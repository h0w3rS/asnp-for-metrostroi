--------------------------------------------------------------------------------
-- ASNP announcer and announcer-related code for 81-70*/81-71* trains
--------------------------------------------------------------------------------
-- Copyright (C) 2013-2018 Metrostroi Team & FoxWorks Aerospace s.r.o.
-- Contains proprietary code. See license.txt for additional information.
--------------------------------------------------------------------------------


-- Редакция 2023 года для Metrostroi ЪЕЪ

Metrostroi.DefineSystem("81_71_ASNP")
TRAIN_SYSTEM.DontAccelerateSimulation = true
function TRAIN_SYSTEM:Initialize()
    self.LineOut = 0

    self.TriggerNames = {
        "R_ASNPMenu",
        "R_ASNPUp",
        "R_ASNPDown",
        "R_ASNPOn",
        "R_Program1",
        "R_Program2",
        "R_Program1H",
        "R_Program2H",
        --R_Announcer
        --R_Line
    }
    self.Triggers = {}

    self.State = 0

    self.Line = 1
    self.Path = false
    self.Station = 1
    self.Arrived = true
    self.StopMessage = false
    self.RouteNumber = 0
    self.SelectStation = 0

    self.Line = 1

    if not self.Train.R_ASNPOn then
        self.Train:LoadSystem("R_ASNPOn","Relay","Switch", { normally_closed = true, bass = true })
        self.Train:LoadSystem("R_ASNPMenu","Relay","Switch", { bass = true })
        self.Train:LoadSystem("R_ASNPUp","Relay","Switch", { bass = true })
        self.Train:LoadSystem("R_ASNPDown","Relay","Switch", { bass = true })
    end

    self.K1 = 0
    self.K2 = 0

    self.Timer = CurTime()

    self.NextStation = 0
    self.CheckArrived = false
    self.CheckStation = 0
    self.CheckPath = true
end

if TURBOSTROI then return end

function TRAIN_SYSTEM:Inputs()
    return { "Disable" }
end

function TRAIN_SYSTEM:Outputs()
    return { "K1", "K2", "LineOut" }
end

function TRAIN_SYSTEM:TriggerInput(name,value)
    if name == "Disable" then
        self.Disable = value > 0
        if self.Disable then self:Initialize() end
    end
end
if CLIENT then
    local function createFont(name,font,size)
        surface.CreateFont("Metrostroi_"..name, {
            font = font,
            size = size,
            weight = 500,
            blursize = false,
            antialias = true,
            underline = false,
            italic = false,
            strikeout = false,
            symbol = false,
            rotary = false,
            shadow = false,
            additive = false,
            outline = false,
            extended = true,
            scanlines = false,
        })
    end
    createFont("ASNP","Liquid Crystal Display",30,400)
    function TRAIN_SYSTEM:ClientThink()
    if not self.Train:ShouldDrawPanel("ASNPScreen") then return end

        if not self.DrawTimer then
            render.PushRenderTarget(self.Train.ASNP,0,0,512, 128)
            render.Clear(0, 0, 0, 0)
            render.PopRenderTarget()
        end
		
        if self.DrawTimer and CurTime()-self.DrawTimer < 0.1 then return end
        self.DrawTimer = CurTime()
        render.PushRenderTarget(self.Train.ASNP,0,0,512, 128)

        cam.Start2D()
            self:ASNPScreen(self.Train)
        cam.End2D()
        render.PopRenderTarget()
    end
	
    -- перевод мелких букв на капс
	local symb = {
		["а"] = 'А',["б"] = 'Б',["в"] = 'В',["г"] = 'Г',["д"] = 'Д',["е"] = 'Е',["ё"] = 'Ё',["ж"] = 'Ж',["з"] = 'З',["и"] = 'И',["й"] = "Й",
		["к"] = "К",["л"] = "Л",["м"] = 'М',["н"] = 'Н',["о"] = 'О',["п"] = 'П',["р"] = 'Р',["с"] = 'С',["т"] = 'Т',["у"] = 'У',["ф"] = 'Ф',
		["х"] = 'Х',["ц"] = 'Ц',["ч"] = 'Ч',["ш"] = 'Ш',["щ"] = 'Щ',["ъ"] = 'Ъ',["ы"] = 'Ы',["ь"] = 'Ь',["э"] = 'Э',["ю"] = 'Ю',["я"] = 'Я',
		
		["a"] = "A",["b"] = "B",["c"] = "C",["d"] = "D",["e"] = "E",["f"] = "F",["g"] = "G",["h"] = "H",["i"] = "I",["j"] = "J",["k"] = "K",["l"] = "L",["m"] = "M",
		["n"] = "N",["o"] = "O",["p"] = "P",["q"] = "Q",["r"] = "R",["s"] = "S",["t"] = "T",["u"] = "U",["v"] = "V",["w"] = "W",["x"] = "X",["y"] = "Y",["z"] = "Z", 
	}
	
    function TRAIN_SYSTEM:PrintText(x, y, text, inverse, align, station)
        local str = {utf8.codepoint(text,1,-1)}
		if align == "right" and str then x = x-#str end	
        for i=1,#str do
            local char = utf8.char(str[i])
            if inverse then
			
                draw.SimpleText(string.char(0x7f),"Metrostroi_ASNP",(x+i)*20.5+5,y*40+40,Color(0,0,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                draw.SimpleText(char,"Metrostroi_ASNP",(x+i)*20.5+5,y*40+40,Color(140,190,0,150),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
				
            else
				if char == "I" and text:find("II") and self.Train:GetNW2Int("ASNP:State",-1) == 6 then
				
					draw.SimpleText("I","Metrostroi_ASNP",(x+i)*20.5-1,y*40+40,Color(0,0,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
					draw.SimpleText("I","Metrostroi_ASNP",(x+i)*20.5+11,y*40+40,Color(0,0,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
					break
					
				else
				
					draw.SimpleText(station and symb[char] or char,"Metrostroi_ASNP",(x+i)*20.5+5,y*40+40,Color(0,0,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
					
				end
            end
        end
    end
	
	
    TRAIN_SYSTEM.LoadSeq = "/-\\|"
    function TRAIN_SYSTEM:ASNPScreen(Train) -- вывод информации на экран АСНП
        local State = self.Train:GetNW2Int("ASNP:State",-1)
        if State ~= 0 then
            surface.SetDrawColor(140,190,0,self.Warm and 130 or 255)
            self.Warm = true
        else
            surface.SetDrawColor(20,50,0,230)
            self.Warm = false
        end
        surface.DrawRect(0,0,512,128)
        if State == 0 then
            return
        end


        if State == -2 then
		
            self:PrintText(0, 0, "Ошибка памяти")
            self:PrintText(0, 1, "Карта не поддерживается")
			
            return
        end

        if State == 1 then
		
            self:PrintText(0, 0, "ПНМ4 АСНП  ваг.N"..tostring(Train.WagonNumber):sub(1,5))
            self:PrintText(0 ,1, " ver.R.04 ММС 2018г.")
			
        end
		
        if State > 1 and not Metrostroi.ASNPSetup then
		
            self:PrintText(0, 0, "Ошибка памяти")
            self:PrintText(0, 1, "Флеш-карта не найдена")
			
            return
        end
		
        local stbl = Metrostroi.ASNPSetup and Metrostroi.ASNPSetup[Train:GetNW2Int("Announcer",1)]
        if State > 2 and not stbl then
		
            self:PrintText(0, 0, "Ошибка памяти")
            self:PrintText(0, 1, "Флеш-карта не найдена")
			
            return
        end
		
		if State == 2 then
		
			local Line = self.Train:GetNW2Int("ASNP:Line", 1)
            local ltbl = stbl[Line]
			
            self:PrintText(0, 0, "Выберите линию  -")
			self:PrintText(2, 1, (ltbl.Name or "Не найдена"))
		end
		
        if State == 3 then
		
		    local sel = Train:GetNW2Int("ASNP:Selected", 0)
			local path = Train:GetNW2Bool("ASNP:Path", false)
            self:PrintText(0, 0, "Выбор направления  -")
			self:PrintText(2, 1, "ПУТЬ "..string.rep("I",path and 2 or 1))
			
        end


        if State == 4 then

            local RouteNumber = Format("%02d", Train:GetNW2Int("ASNP:RouteNumber",0))
            local sel = Train:GetNW2Int("ASNP:Selected", 0)
            self:PrintText(0, 0, "Выбор N маршрута")
			if RouteNumber[1] ~= "0" then self:PrintText(0,1,RouteNumber[1]) end
            self:PrintText(1,1,RouteNumber[2])
			
        end

        if State == 5 then

            local sel = Train:GetNW2Int("ASNP:Selected", 1)
            local Line = Train:GetNW2Int("ASNP:Line", 1)
			local station = Train:GetNW2Int("ASNP:Station", 1)
			local path = Train:GetNW2Bool("ASNP:Path", false)		
            local ltbl = stbl[Line]	
			local curr = ltbl[sel]
            
			if not self.tbllasts or Line ~= self.Line or path ~= self.Path or station ~= self.Station then
			
				self.tbllasts = {}
				if ltbl.Loop then
					table.insert(self.tbllasts,"КОЛЬЦЕВОЙ")
				end	
				
				if path then
					for i = 1, math.min(station, #ltbl - 1) do
						if ltbl[i].arrlast then
							table.insert(self.tbllasts,ltbl[i])
						end
					end 			
				else
					for i = math.max(2, station), #ltbl do
						if ltbl[i].arrlast then
							table.insert(self.tbllasts,ltbl[i])
						end
					end 				
				end			
				self.Line = Line
				self.Station = station
			end
			

            self:PrintText(0,0,"Выбор ст. оборота  -")
            self:PrintText(0, 1, istable(self.tbllasts[sel]) and self.tbllasts[sel][2] or self.tbllasts[sel],false,false,true)
        end

        if State == 6 then
		
            local sel = Train:GetNW2Int("ASNP:Selected", 0)
            local Line = Train:GetNW2Int("ASNP:Line", 1)
			local path = Train:GetNW2Bool("ASNP:Path", false)

            local ltblconv = #stbl[Line] + 1
			if sel == 0 then self:PrintText(4, 0, "НАЧАЛЬНАЯ СТАНЦИЯ")
            elseif sel == ltblconv then self:PrintText(4, 0, "КОНЕЧНАЯ СТАНЦИЯ")
            else 
                local ltbl = stbl[Line]
                local curr = ltbl[sel][2]
                local find = false
                for i=1,#stbl do
                    local l = stbl[i]
                    for k = 1,#l do
                        if l[k][2] == curr and i ~= Line then
                            find = true
                        end
                    end
                end

                self:PrintText(0, 0, "Текущая станция  -")
                self:PrintText(0, 1, curr..(find and (" ("..Line..")") or ""), false, false, true)
            end
			
        end

        if State == 7 then

            self:PrintText(0, 0, "Выбор приб / отпр")
            self:PrintText(0, 1, (self.Train:GetNW2Bool("ASNP:Arrived", false) and "Отпр." or "Приб."))

        end
        
        if State == 8 then
		
			local path = Train:GetNW2Bool("ASNP:Path", false)	
            local RouteNumber = Format("%02d",Train:GetNW2Int("ASNP:RouteNumber", 0))
            local Line = Train:GetNW2Int("ASNP:Line", 1)
			local station = Train:GetNW2Int("ASNP:Station", 1)
            local ltbl = stbl[Line]			
			local last = Train:GetNW2Int("ASNP:LastStation", 1)

            if Train:GetNW2Bool("ASNP:StopMessage", false) then 

                self:PrintText(2.5, 0, "ПЕРЕД ОТПРАВЛЕНИЕМ")
                self:PrintText(0, 1, "НАЖМИ КНОПКУ   ОБЪЯВИТЬ")
                
            else

                self:PrintText(0, 0, (self.Train:GetNW2Bool("ASNP:Arrived", false) and "Отпр." or "Приб."))
                
                self:PrintText(6, 0, ltbl[station][2], false, false, true)

                if Train:GetNW2Bool("ASNP:Playing", false) then self:PrintText(0, 1, "<<<  ИДЁТ ОБЪЯВЛЕНИЕ  >>>")
                else 

                    self:PrintText(0, 1, string.rep("I", path and 2 or 1))

                    if Train:GetNW2Bool("ASNP:IKPORT", false) then self:PrintText(5, 0, "$")				
                    elseif Train:GetNW2Bool("ASNP:StationArr", false) then self:PrintText(5, 0, "+")
                    end
                    
                    if RouteNumber[1] ~= "0" then self:PrintText(2.5, 1, RouteNumber[1]) end
                    self:PrintText(3.5, 1, RouteNumber[2])

                    self:PrintText(6, 1, (last == -1 and "КОЛЬЦЕВОЙ" or ltbl[last][2]:upper()), false, false, true)
                   
                    if Train:GetNW2Bool("ASNP:CanLocked", false) then

                        if Train:GetNW2Bool("ASNP:LockedL", false) then self:PrintText(20, 0, "Бл.Л") end
                        if Train:GetNW2Bool("ASNP:LockedR", false) then self:PrintText(20, 1, "Бл.П") end

                    end

                end
            end

        end
    end
    
    return
end

function TRAIN_SYSTEM:Zero()

    self.Station = self.FirstStation

    self.Arrived = true
    self:UpdateBoards()

end

function TRAIN_SYSTEM:Next()
    local tbl = Metrostroi.ASNPSetup[self.Train:GetNW2Int("Announcer",1)][self.Line]

    if tbl.Loop then -- кольцевой

        if self.Arrived then

            self.Station = self.Path and (self.Station == #tbl and 1 or self.Station+1) or (self.Station == 1 and #tbl or self.Station-1)

            self.Arrived = false

        else self.Arrived = true
        end

    else

        if self.Arrived then
		
            if self.Station ~= self.LastStation then

                self.Station = self.Path and math.max(self.Station - 1, self.LastStation) or math.min(self.LastStation, self.Station + 1)
                self.Arrived = false

            end

        else self.Arrived = true

        end

    end
    self:UpdateBoards()
end
function TRAIN_SYSTEM:Prev()

    local tbl = Metrostroi.ASNPSetup[self.Train:GetNW2Int("Announcer",1)][self.Line]

    if tbl.Loop then
	
		if self.Arrived == false then
		
			self.Station = self.Path and (self.Station == 1 and #tbl or self.Station-1) or (self.Station == #tbl and 1 or self.Station+1)	-- кольцевой
			self.Arrived = true
			
		else self.Arrived = false
		end
		
    else
		if self.Station == self.FirstStation then return end
		
		if self.Station == self.LastStation then
		
			self.Station = self.Path and math.min(self.FirstStation, self.Station + 1) or math.min(self.FirstStation, self.Station - 1) -- обычный смертный
			self.Arrived = true
			
			return
		end
		
		if self.Arrived == false then
		
			self.Station = self.Path and math.min(self.FirstStation, self.Station + 1) or math.min(self.FirstStation, self.Station - 1) -- обычный смертный
			self.Arrived = true
			
		else self.Arrived = false
		
		end
   end

    self:UpdateBoards()
end

function TRAIN_SYSTEM:AnnQueue(msg)

    local Announcer = self.Train.Announcer
    if msg and type(msg) ~= "table" then Announcer:Queue{msg}
    else Announcer:Queue(msg)
    end

end

function TRAIN_SYSTEM:Play(dep, not_last)

    local tbl = Metrostroi.ASNPSetup[self.Train:GetNW2Int("Announcer",1)][self.Line]
    local stbl = tbl[self.Station]

    local message, last, lastst
    local path = self.Path and 2 or 1


    if tbl.Loop then -- кольцевой

        last = self.LastStation
        lastst = not dep and self.LastStation > 0 and self.Station == last and tbl[last].arrlast

    else
        last = self.LastStation -- self.Path and self.FirstStation or self.LastStation
        lastst = not dep and self.Station == last and tbl[last].arrlast
    end


    if dep then message = stbl.dep[path]
    else

        if lastst then

            -- выдача информации о конечной в случае, если по 2-му пути она отсутствует
            if stbl.arrlast[path] == nil then path = self.Path and 1 or 2 end

            message = stbl.arrlast[path]
        else 
            message = stbl.arr[path]
        end
    end

    self:AnnQueue{"click1", "buzz_start"}

    if lastst and not stbl.ignorelast then 
        self:AnnQueue(-1) 
    end


    self:AnnQueue(message)

    if self.LastStation > 0 and not dep and self.Station ~= last and tbl[last].not_last and (stbl.have_inrerchange or math.abs(last-self.Station) <= 3) then
        local lstbl = tbl[last]
        if stbl.not_last_c then
            local patt = stbl.not_last_c[path]
            self:AnnQueue(lstbl[patt] or lstbl.not_last)
        else
            self:AnnQueue(lstbl.not_last)
        end
    end

    self:AnnQueue{"buzz_end", "click2"}
    self:UpdateBoards()
end

function TRAIN_SYSTEM:CANReceive(source, sourceid, target, targetid, textdata, numdata)
    if sourceid == self.Train:GetWagonNumber() then return end
    if textdata == "RouteNumber" then self.RouteNumber = numdata end
    if textdata == "Path" then self.Path = numdata > 0 end
    if textdata == "Line" then self.Line = numdata end
    if textdata == "FirstStation" then self.FirstStation = numdata end
    if textdata == "LastStation" then self.LastStation = numdata end
    if textdata == "Activate" then

        local tbl = Metrostroi.ASNPSetup[self.Train:GetNW2Int("Announcer",1)][self.Line]
        self.Station = tbl.Loop and 1 or self.Path and self.LastStation or self.FirstStation
        self.Arrived = true
        self.State = 8

    end
end

function TRAIN_SYSTEM:UpdateBoards()
    if not self.PassSchemeWork then return end
    local tbl = Metrostroi.ASNPSetup[self.Train:GetNW2Int("Announcer",1)][self.Line]
    local stbl = tbl.LED
    local last = self.Path and self.FirstStation or self.LastStation

    local curr = 0
    if self.Path then -- 2 путь
        for i=#stbl,self.Station+1,-1 do
            if stbl[i] then
                curr = curr + stbl[i]
            end
        end
    else -- 1 путь
        for i=1,self.Station-1 do
            if stbl[i] then
                curr = curr + stbl[i]
            end
        end
    end

    local nxt = 0
    if self.Arrived then curr = curr + stbl[self.Station]
    else nxt = stbl[self.Station]
    end

    self.Train:CANWrite("ASNP",self.Train:GetWagonNumber(),"PassSchemes",nil,"Current",curr)
    self.Train:CANWrite("ASNP",self.Train:GetWagonNumber(),"PassSchemes",nil,"Arrival",nxt)
    self.Train:CANWrite("ASNP",self.Train:GetWagonNumber(),"PassSchemes",nil,"Path", self.Path)
    self.Train:CANWrite("ASNP",self.Train:GetWagonNumber(),"Tickers",nil,"Next", not self.Arrived)
    self.Train:CANWrite("ASNP",self.Train:GetWagonNumber(),"Tickers",nil,"Curr", tbl[self.Station][2])
    self.Train:CANWrite("ASNP",self.Train:GetWagonNumber(),"Tickers",nil,"Last", tbl[last] and tbl[last].not_last and tbl[last][2])
end

--[[

            Расшифровка переменных

        R_ASNPUp - кнопка вверх
        R_ASNPDown - кнопка вниз
        R_ASNPMenu - кнопка меню

        Up1 - тоже кнопка вверх. используется для номера маршрута, линий
        Down1 - аналогично что сверху, но понижение значения

            Статусы 
        1 - АСНП только включилась
        2 - Выбор линии
        3 - Выбор пути
        4 - Выбор маршрута
        5 - Выбор конечной станции
        6 - Выбор текущей станции
        7 - Статус прибытия или отправления
        8 - Обычный рабочий статус АСНП
        9 - Сработка при объявлении
]]

function TRAIN_SYSTEM:Trigger(name, value)

    local stbl = Metrostroi.ASNPSetup[self.Train:GetNW2Int("Announcer",1)]
	if not stbl then return end

	local ltbl = stbl[self.Line]
	if not ltbl then return end

    if (name == "R_Program2" or name == "R_Program2H") and value and self.LineOut == 0 then
	
        if self.State ~= 8 and ltbl and ltbl.spec_last then
            self:AnnQueue{"click1","buzz_start"}
            self:AnnQueue(-1)
            self:AnnQueue(ltbl.spec_last)
            self:AnnQueue{"buzz_end","click2"}
			
        elseif self.State == 8 then

            local last,lastst
            if self.Arrived then

                if stbl.Loop then -- кольцевой

                    ltbl = self.LastStation
                    lastst = self.LastStation > 0 and self.Station == last and ltbl[last].arrlast

                else

                    last = self.Path and self.FirstStation or self.LastStation
                    lastst = self.Station == last and ltbl[last].arrlast

                end
            end

            if lastst and not ltbl[last].ignorelast then

                self:AnnQueue{"click1","buzz_start"}
                self:AnnQueue(-1)
                self:AnnQueue(ltbl.spec_last)
                self:AnnQueue{"buzz_end","click2"}

            else -- объявления о ожидании отправки поезда
                
                self.StopMessage = not self.StopMessage
                
                self:AnnQueue{"click1","buzz_start"}

                self:AnnQueue(ltbl.spec_wait[self.StopMessage and 1 or 2])

                self:AnnQueue{"buzz_end","click2"}

            end
        end
    end
	
	if self.State >= 1 then
	
		if name == "R_ASNPUp" and value then self.UpTimer = CurTime() end

		if name == "R_ASNPUp" and not value then
			self.UpTimer = nil
			self.Up = false
		end	

		if name == "R_ASNPDown" and value then self.DownTimer = CurTime() end

		if name == "R_ASNPDown" and not value then
			self.DownTimer = nil
			self.Down = false
		end	
		
	end
	
	if self.State == 1 and value then
	
		if name == "R_ASNPMenu" then -- применение

			self.Selected = 0

            self.LastStation = 0
            self.FirstStation = 0

			self.State = 2
			self.ReturnTimer = CurTime()
            
		end
		
    elseif self.State == 2 and value then -- выбор линии

        if name == "Down1" and value then -- Кнопка вниз

            self.ReturnTimer = CurTime()
            self.Line = self.Line + 1

            if self.Line > #stbl then self.Line = 1 end

        end

        if name == "Up1" and value then -- Кнопка вверх

            self.ReturnTimer = CurTime()
            self.Line = math.max(1,self.Line - 1)
            if self.Line < 1 then self.Line = #tbl end

        end

        if name == "R_ASNPMenu" and value then -- применение

            self.State = 3
            self.ReturnTimer = CurTime()

        end

	elseif self.State == 3 and value then	-- установка номера пути
	
		if name == "R_ASNPMenu" then -- применение

            -- выставление текущей станции в соотв. с номером пути
            if self.Station == (self.Path and 1 or #ltbl) then

                self.Station = (self.Path and #ltbl or 1)
                self.Arrived = true

            end

			self.State = 4
			self.ReturnTimer = CurTime()		
		end		

		if (name == "Up1" or name == "Down1") then -- Кнопка вверх и вниз
			
            self.Path = not self.Path

            self.Station = (self.Path and #ltbl or 1)
            self.Arrived = true

			self.ReturnTimer = CurTime()		
		end
		
	elseif self.State == 4 and value then -- установка номера маршрута

		if name == "R_ASNPMenu" then -- применение

            self.Selected = 1 -- установка числа, которое отвечает за номер конечки

			self.State = 5
			self.ReturnTimer = CurTime()

		end
		
		if name == "Up1" then -- Кнопка вверх
			self.RouteNumber = self.RouteNumber == 99 and 0 or self.RouteNumber + 1
			self.ReturnTimer = CurTime()
		end
		
		if name == "Down1" then -- Кнопка вниз
			self.RouteNumber = self.RouteNumber == 0 and 99 or self.RouteNumber - 1
			self.ReturnTimer = CurTime()
		end		
		
	elseif self.State == 5 and value then -- установка конечной станции

		local tbl = {}

		if ltbl.Loop then table.insert(tbl, "КОЛЬЦЕВОЙ") end

        if self.Path then -- конечные станции по 2 пути

            for i = 1, math.min(self.Station, #ltbl-1) do
                if ltbl[i].arrlast then
                    table.insert(tbl,{ltbl[i],i})
                end
            end 	

        else -- 1 путь

            for i = math.max(2, self.Station),#ltbl do
                if ltbl[i].arrlast then
                    table.insert(tbl,{ltbl[i],i})
                end
            end 	

        end	

		if name == "Up1" then -- Кнопка вверх

			self.Selected = math.max(1, self.Selected - 1)
            self.ReturnTimer = CurTime()

		end

		if name == "Down1" then -- Кнопка вниз

			self.Selected = math.min(#tbl, self.Selected + 1)
            self.ReturnTimer = CurTime()
		end

		if name == "R_ASNPMenu" then -- применение

            self.FirstStation = self.Path and #ltbl or 1

            -- запись конечной
            self.LastStation = isstring(tbl[self.Selected]) and -1 or tbl[self.Selected][2]

            -- выставление текущей станции
            self.Selected = self.Station

            self.State = 6
            self.ReturnTimer = CurTime()
                
		end

	elseif self.State == 6 and value then -- установка текущей станции
	
		if name == "Down1" then -- Кнопка вниз

            local convert = #ltbl + 1
			self.Selected = math.min(convert, self.Selected + 1)

			if self.Selected == convert then 

                self.SelectStation = convert - 1
                self.ReturnSelected = CurTime() 

            else self.ReturnSelected = nil end

            self.ReturnTimer = CurTime()
		end
		
		if name == "Up1" then -- Кнопка вверх 

			self.Selected = math.max(0, self.Selected - 1)
			if self.Selected == 0 then 

                self.SelectStation = 1
                self.ReturnSelected = CurTime() 

            else self.ReturnSelected = nil end

            self.ReturnTimer = CurTime()

		end
		
		if name == "R_ASNPMenu" then -- применение 

            self.ReturnSelected = nil

			self.Station = self.Selected
            self.NextStation = self.Selected

			self.State = 7
			self.ReturnTimer = CurTime()
		end
		
    elseif self.State == 7 and value then -- выбор статуса прибытия или отправления

        if (name == "Up1" or name == "Down1") then -- Кнопка вверх и вниз

            -- редактирование статуса. офк если выбранная станция равняется конечной, запрещается выбирать статус
            if self.LastStation ~= self.Station then self.Arrived = true
            else self.Arrived = not self.Arrived
            end

            self.ReturnTimer = CurTime()
        end

        if name == "R_ASNPMenu" then -- применение 

            -- иницилизация аснп и выдача ему рабочего состояния

			self.Init = true
			self.State = 8
			self.ReturnTimer = nil

        end

	elseif self.State == 8 and value then -- обычный статус при работе
		
		if name == "R_ASNPMenu" then -- возвращение к редактированию и выставление таймера бездействия при настройке АСНП

			self.State = 2
			self.ReturnTimer = CurTime()

		end
		
		if name == "Up1" and value then self:Prev() end -- предыдущие станции
        if name == "Down1" and value then self:Next() end -- след. станции

		if (name == "R_Program1" or name == "R_Program1H") and value and self.LineOut == 0 then -- объявления

            -- если игрок не отправился со станции
            if self.CheckArrived == true then

                self.Path = self.CheckPath
                self:Play(true)

                return

            end

            -- если прибывает на конечку
            if self.Arrived and self.Station == self.LastStation then
                self:Zero() 
            end

			-- проигрывание информации и выдача след. станции
            self:Play(self.Arrived)
            self:Next()

        end
		
		
    end
end


function TRAIN_SYSTEM:Think()
    if self.Disable then return end

    local Train = self.Train
    local VV = Train.ASNP_VV
    local Power = VV.Power > 0.5

    if not Power and self.ASNPState ~= 0 then
        self.State = 0
        self.ASNPTimer = nil
    end
    
    if Power and self.State == 0 then
        self.State = -1
        self.ASNPTimer = CurTime()-math.Rand(-0.3,0.3)
    end

    -- таймер включения АСНП
    if self.State == -1 and self.ASNPTimer and CurTime()-self.ASNPTimer > 1 then
        self.State = Metrostroi.ASNPSetup and 1 or -2
    end
	
    if Power and self.State > -1  then

        for k,v in pairs(self.TriggerNames) do

            if Train[v] and (Train[v].Value > 0.5) ~= self.Triggers[v] then
                self:Trigger(v,Train[v].Value > 0.5)
                self.Triggers[v] = Train[v].Value > 0.5
            end

        end

    end

    if not Metrostroi.ASNPSetup and self.State > 0 then
        self.State = -2
    end

    local PSWork = Train.Panel.PassSchemeControl and Train.Panel.PassSchemeControl>0 and self.State==8
    if PSWork~=self.PassSchemeWork then
        self.PassSchemeWork = PSWork
        if self.PassSchemeWork then self:UpdateBoards() end
    end
	
    -- если таймер бездействия при настройке АСНП истёк
	if VV and self.State > 1 and self.State ~= 8 and self.ReturnTimer and CurTime()-self.ReturnTimer > 10 then
	
		for i=1,8-self.State do

			self:Trigger("R_ASNPMenu",true)
            
		end

	end

    -- возвращение к номеру станции при выборе текущей
    if self.ReturnSelected and CurTime() - self.ReturnSelected > 0.5 then 

        self.Selected = self.SelectStation
        self.ReturnSelected = nil

    end
	
    -- таймер тригера зажатия кнопки вверх и вниз

	if self.UpTimer and CurTime()-self.UpTimer > 0.5 then

		if (CurTime()-self.UpTimer)%0.2 < 0.1 and not self.Up then

			self:Trigger("Up1",true)
			self.Up = true

		elseif (CurTime()-self.UpTimer)%0.2 > 0.1 and self.Up then
			self.Up = false
		end

	elseif self.UpTimer and not self.Up then

		self:Trigger("Up1",true)		
		self.Up = true

	end

	if self.DownTimer and CurTime()-self.DownTimer > 0.5 then

		if (CurTime()-self.DownTimer)%0.2 < 0.1 and not self.Down then

			self:Trigger("Down1",true)
			self.Down = true

		elseif (CurTime()-self.DownTimer)%0.2 > 0.1 and self.Down then
			self.Down = false
		end

	elseif self.DownTimer and not self.Down then

		self:Trigger("Down1",true)
		self.Down = true

	end
	
    -- запись переменных
    Train:SetNW2Int("ASNP:State",self.State)                    -- статусы АСНП
    Train:SetNW2Int("ASNP:RouteNumber",self.RouteNumber)        -- номер маршрута

    Train:SetNW2Int("ASNP:Selected", self.Selected)             -- что выбрано
    Train:SetNW2Int("ASNP:Line", self.Line)                     -- линия
    Train:SetNW2Int("ASNP:FirstStation", self.FirstStation)     -- первая станция
    Train:SetNW2Int("ASNP:LastStation", self.LastStation)       -- последняя станция
    Train:SetNW2Bool("ASNP:Path", self.Path)                    -- номер пути

    Train:SetNW2Bool("ASNP:Station", self.Station)              -- станция где сейчас
    Train:SetNW2Bool("ASNP:Arrived", self.Arrived)              -- статус "приб", "отпр"

    self.LineOut = #Train.Announcer.Schedule > 0 and 1 or 0

    Train:SetNW2Bool("ASNP:Playing", self.LineOut > 0)          -- проигрывание информатора
    Train:SetNW2Bool("ASNP:StopMessage", self.StopMessage)		-- сообщение остановки
    Train:SetNW2Bool("ASNP:ReturnSelected", self.SelectStation) -- восстановление статуса 
	
    -- блокировка дверей
    if Train.VBD and self.State > 0 then
	
        Train:SetNW2Bool("ASNP:CanLocked",true)
        if self.State < 7 then

            self.K1 = 1
            self.K2 = 1
            self.StopTimer = nil

        elseif Train.ALSCoil.Speed>1 then
            self.K1 = 0
            self.K2 = 0
            self.StopTimer = nil
        else
            if self.StopTimer==nil then self.StopTimer = CurTime() end
            if self.StopTimer and CurTime()-self.StopTimer >= 10 then
                self.StopTimer = false
            end
            local tbl = Metrostroi.ASNPSetup[self.Train:GetNW2Int("Announcer",1)]
            local stbl = tbl[self.Line] and tbl[self.Line][self.Station]
            if not stbl or not tbl[self.Line].BlockDoors or self.Arrived and self.Station == (self.Path and self.FirstStation or self.LastStation) then

                self.K1 = 1
                self.K2 = 1

            elseif self.Arrived then

                self.K1 = (stbl.both_doors or not stbl.right_doors) and 1 or 0
                self.K2 = (stbl.both_doors or     stbl.right_doors) and 1 or 0

            elseif self.StopTimer~=false then

                self.K1 = 0
                self.K2 = 0

            else

                self.K1 = 1
                self.K2 = 1

            end
        end

        Train:SetNW2Bool("ASNP:LockedL", self.K1==0)
        Train:SetNW2Bool("ASNP:LockedR", self.K2==0)


    else

        Train:SetNW2Bool("ASNP:CanLocked",false)
        self.K1 = 0
        self.K2 = 0
        self.StopTimer = false

    end

    if self.State == 8 then -- рабочий статус аснп
	
        local path = Train:ReadCell(49170)
		local station = Train:ReadCell(49169)		
		local stbl
		if station ~= 0 and path ~= 0 then

			stbl = Metrostroi.Stations[station][path]
			local ltbl = Metrostroi.ASNPSetup[Train:GetNW2Int("Announcer",1)][self.Line]

			-- получение дистанции до метки
			local dist = Train:ReadCell(49165)-6.5
			
            -- если человек покинул станцию
            if dist > 40 and self.CheckArrived == true then

                self:Next()

                self.CheckArrived = false
                self.CheckStation = 0
                self.CheckPath = false

               -- print ("[debug] убрал информацию о check arrived, station, path")
                return
            end

			if not dist or Train:ReadCell(49165) == 0 then return end

			local find,find2 = false,false
			if dist < 40 then

				if CurTime()-self.Timer > 0 then
					self.Timer = CurTime()+math.Rand(2.5,3)		
				end

				if CurTime()-self.Timer > -1 and CurTime()-self.Timer < 0 then

                    -- переменная номера станции и поиск её из конфига карты
					local st = 0
					for i=1,#ltbl do
						local Map = game.GetMap() or ""
						if ltbl[i][1] == station or (Map:find("gm_metro_crossline_c") and ltbl[i][1] == station-799) then

                            st = i
							break
						end
					end

                    local Map = game.GetMap() or ""
                    if (Map:find("gm_metro_pink_line_redux_v1")) then st = st - 1 end

					-- если станции вообще нет
					if st == 0 then return end
					
					-- если она активная после объявления
                    if self.CheckArrived == true then 
                        find = true
                        return 
                    end

					-- если текущая станция равняется начальной
                    if st == self.FirstStation then
                        find = true
                        return
                    end
					
					-- выдача пути при неверной настройке АСНП
					
					local get_line = false
					if Train:ReadCell(49168) == 2 then get_line = true end
					
					if self.Path != get_line then
					
						self.Path = get_line 
						
						local tbl = {}

						if ltbl.Loop then table.insert(tbl, "КОЛЬЦЕВОЙ") end

						if self.Path then -- конечные станции по 2 пути

							for i = 1, math.min(self.Station, #ltbl-1) do
								if ltbl[i].arrlast then
									table.insert(tbl,{ltbl[i],i})
								end
							end 	

						else -- 1 путь

							for i = math.max(2, self.Station),#ltbl do
								if ltbl[i].arrlast then
									table.insert(tbl,{ltbl[i],i})
								end
							end 	

						end	


						self.FirstStation = self.Path and #ltbl or 1
						self.LastStation = isstring(tbl[self.Selected]) and -1 or tbl[self.Selected][2]

						
					end
                
                    -- выдача номера след. станции
                    if self.Path then 
                        self.NextStation = st - 1
                       -- print ("[debug] если path = true")
                    else 
                        self.NextStation = st + 1
                        --print ("[debug] если path = false")
                    end

                    --print ("station: ".. st)


                    -- запись в хранение
                    self.CheckArrived = true
                    self.CheckStation = st
                    self.CheckPath = self.Path

                    self.Station = st 

                    -- проигрывание записи информатора
                    self:Play(false)
                    self.Arrived = true

					find = true								
				end

			end

			find2 = math.abs(dist) < 9 and (CurTime()%2 < 0.2 or CurTime()%2 > 1.8)--IKPORT
			if find2 then

				local st = 0
				local Map = game.GetMap() or ""
				for i=1,#ltbl do
					if ltbl[i][1] == station or (Map:find("gm_metro_crossline_c") and ltbl[i][1] == station-799) then
						st=i
						break
					end	
				end

				if st == 0 then return end					
				
			end

			Train:SetNW2Bool("ASNP:StationArr", find)
			Train:SetNW2Bool("ASNP:IKPORT", find2)			
		end
	end
end
