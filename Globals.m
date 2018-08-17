% This simulation was made using MATLAB R2016b
% Italo C. Brito, Leonardo C. Ribeiro, Luci Pirmez, Luiz F. R. C. Carmo, Claudio C. Miceli
% Copyright 2018 - PPGI/UFRJ - LabNet - http://labnet.nce.ufrj.br/
% License: GNU GPLv3 http://www.gnu.org/licenses/gpl.html
% Please, if you use this code, reference us on: 

classdef Globals < handle
    methods(Static)
        
        function [mensal_consumption, cluster_mensal_consumption] = calcMensalConsumption()
            
            % source: "ESTIMAÇÃO DE CURVAS DE CARGA EM PONTOS DE CONSUMO E EM TRANSFORMADORES DE DISTRIBUIÇÃO" Dissertation in portugueese, Aislan Francisquini
            % (page 48, Figure 4.20)
            FEEDER = [1698.778157906429, 1699.1424890034211, 1682.605411649709, 1649.1669258452926, 1657.9997334162704, 1683.7161771893188, 1760.127960190163, 2081.6190518505355, 2141.156084773626, 2166.8725285466744, 2133.4340427422576, 2133.789487714933, 2227.138223663749, 2286.648598213889, 2244.7594081841203, 2278.9265561825205, 2287.7682498778154, 2152.912427244857, 2516.648153907673, 2440.956146976496, 2230.0706446883187, 2044.5194828275646, 2053.334518149909, 1774.825609810281]; % distribution feeder from Sao Paulo city
            % (Page 43, Figure 4.15)
            TRANSFORMER_2 = [8.51593625498008, 7.868525896414344, 7.569721115537849, 7.221115537848604, 7.02191235059761, 7.121513944223111, 7.569721115537849, 13.49601593625498, 14.741035856573705, 14.143426294820717, 14.342629482071713, 14.691235059760956, 14.691235059760956, 17.13147410358566, 17.03187250996016, 17.878486055776893, 18.725099601593627, 19.12350597609562, 21.165338645418327, 18.127490039840637, 15.587649402390438, 13.396414342629482, 13.047808764940239, 10.258964143426294]; % a transformer from Sao Paulo city
            mensal_consumption = sum(FEEDER); % 49.0269 MWh
            cluster_mensal_consumption = sum(TRANSFORMER_2); %320 kWh
        end
        
        function [consumption, dispersion] = calcConsumption(INDIVIDUAL_CONSUMPTION_SM)
            % source: "ESTIMAÇÃO DE CURVAS DE CARGA EM PONTOS DE CONSUMO E EM TRANSFORMADORES DE DISTRIBUIÇÃO" Dissertation in portugueese, Aislan Francisquini (Figure 4.5 Page 38)
            % residential consumer with consumption class between 201 and 300 kWh/month
            CONSUMPTION_CURVE = [0.28, 0.3, 0.24, 0.14, 0.15, 0.11, 0.3, 0.27, 0.27, 0.18, 0.24, 0.38, 0.27, 0.22, 0.22, 0.2, 0.59, 0.57, 0.65, 0.61, 0.53, 0.53, 0.53, 0.28];
            CONSUMPTION_DISPERSION = [0.2, 0.22, 0.18, 0.11, 0.09, 0.05, 0.18, 0.3, 0.18, 0.06, 0.19, 0.19, 0.16, 0.08, 0.1, 0.07, 0.75, 0.44, 0.4, 0.2, 0.2, 0.46, 0.4, 0.18];

            daily_consumption = sum(CONSUMPTION_CURVE);
            consumption_scale = INDIVIDUAL_CONSUMPTION_SM / daily_consumption;

            for i = 1:24
                consumption(i) = CONSUMPTION_CURVE(i) * consumption_scale;
                dispersion(i) = CONSUMPTION_DISPERSION(i) * consumption_scale;
            end
        end
        
        function mean = calcMeanHistory(history, days)
          sum = zeros(1,24);
          
          
              
          for i = 1:24
          
              for day = 0:days-1
                  
                  hour = day*24+i;
                                    
                  sum(i) = sum(i) + history(hour);
                  
              end
              
              mean(i) = sum(i) / days;
                  
          end
          
        end
        
        function wind_power_generated = calcWind(month, MENSAL_WIND_GENERATION)
            
            % speed(m/s)
            wind_speed_hours = [2.3859648705, 1.5, 1.894736886, 1.5438597202, 1.1929824352, 1.8596491814, 4.2105264664, 5.649122715, 6.2105264664, 6.2456140518, 5.7192983627, 5.4736843109, 5.2631578445, 5.1578946114, 5.29824543, 5.4736843109, 5.4035086632, 4.9473686218, 5.29824543, 5.8947367668, 5.8947367668, 5.2280702591, 4.4561405182, 3.649122715];
            %source: "AVALIAÇÃO DO POTENCIAL EÓLICO EM CINCO REGIÕES DO ESTADO DA PARAÍBA." In portugueese, Francisco Lima et all. (Figure 4b)
            wind_speed_months = [4.545454502, 3.606060743, 2.606060743, 2.818181992, 2.666666746, 2.484848499, 3.363636494, 3.363636494, 4.454545498, 5.818181992, 6.333333492, 5.454545498];
            %source: "AVALIAÇÃO DO POTENCIAL EÓLICO EM CINCO REGIÕES DO ESTADO DA PARAÍBA." In portugueese, Francisco Lima et all. (Figure 3b)


            % source: "ANÁLISE DO POTENCIAL EÓLICO E ESTIMATIVA DA GERAÇÃO DE ENERGIA EMPREGANDO O SOFTWARE LIVRE ALWIN". In portugueese, Adriane Petry. (Figure 13)
            wind_power_generation = [0, 2, 18, 56, 127, 240, 400, 626, 892, 1223, 1590, 1830, 1950, 2050];
            wind_fixed = fix(wind_speed_hours); % converting to integer
            for i=1:24
                if(wind_speed_hours(i) >= 14) % Power (Kw), 14 m/s onwards = 2050
                    wind_power_generated(i) = 2050;
                elseif(wind_speed_hours(i) < 2)
                    wind_power_generated(i) = 0;
                else
                    wind_power_generated(i) = wind_power_generation(wind_fixed(i));
                    % adding fraction
                    wind_interval = wind_power_generation(wind_fixed(i)+1)-wind_power_generation(wind_fixed(i));
                    wind_fraction = wind_speed_hours(i)-wind_fixed(i);
                    wind_power_generated(i) = wind_power_generated(i)+(wind_fraction*wind_interval);
                end
            end

            wind_daily_production = sum(wind_power_generated);

            % adjusting to the corresponding month
            wind_max_month = 11;
            wind_scale = wind_speed_months(month) / wind_speed_months(wind_max_month);
            wind_daily_production_desired = MENSAL_WIND_GENERATION * wind_scale;
            wind_scale = wind_daily_production_desired / wind_daily_production;
            for i = 1:24
                wind_power_generated(i) = wind_power_generated(i) * wind_scale;
            end
            
        end
        
        function solar_power_generated = calcSolar(month, SOLAR_MONTH_GENERATION)

            SOLAR_EFFICIENCY = 0.22; % 22 percent
            solar_irradiation_hour = [0, 0, 0, 0, 0, 0.0708333403, 0.2166666836, 0.4416666925, 0.6625000238, 0.8375000358, 0.9541667104, 0.9958333969, 0.9875000715, 0.883333385, 0.7125000358, 0.508333385, 0.275000006, 0.1125000119, 0, 0, 0, 0, 0, 0];
            % source: "SÉRIE  TEMPORAL  DIÁRIA  MÉDIA  HORÁRIA  E  ANUAL  MÉDIA  MENSAL  DIÁRIA  DA IRRADIAÇÃO SOLAR DIFUSA ANISOTRÓPICA" In portugueese, Alexandre pai, João Escobedo. (Figure 4a)
            solar_irradiation_month = [10.211268425, 10.0704231262, 12.6056346893, 13.380282402, 10.0704231262, 9.4366197586, 10.1408452988, 11.2676057816, 10.9154930115, 12.3943662643, 12.1126766205, 11.197183609];
            % source: "SÉRIE  TEMPORAL  DIÁRIA  MÉDIA  HORÁRIA  E  ANUAL  MÉDIA  MENSAL  DIÁRIA  DA IRRADIAÇÃO SOLAR DIFUSA ANISOTRÓPICA" In portugueese, Alexandre pai, João Escobedo. (Figure 6)
            for i = 1:24
                solar_power_hour(i) = solar_irradiation_hour(i)*SOLAR_EFFICIENCY;
            end

            solar_daily_production = sum(solar_power_hour);
            solar_max_month = 4;
            solar_scale = solar_irradiation_month(month) / solar_irradiation_month(solar_max_month);
            solar_daily_production_desired = SOLAR_MONTH_GENERATION * solar_scale;
            solar_scale = solar_daily_production_desired / solar_daily_production;

            for i = 1:24
                solar_power_generated(i) = solar_power_hour(i) * solar_scale;
            end
        
        end
        
        function [hydro_power_generated] = calcHydro(clean_energy_generation, consumption)
           
            % difference between consumption and clean generation (wind+solar)

            for i = 1:24
                hydro_power_generated(i) = double(consumption(i)) - clean_energy_generation(i);
                % if clean energy is bigger than consumption, hydro generation = 0 
                if hydro_power_generated(i) < 0
                    hydro_power_generated(i) = 0;
                end
            end
            
        end
        
        function [SM_List, LH_List, IH_List, RH] = create_nodes(SMART_METERS_CLUSTERS, LeafHubs, IntermediateHubs, nodes_cluster_LH)
            
            
            RH = RootHub(1);
            RH.PU = rand(1)*1000;
            RH.nodes_IH = IntermediateHubs;


            IH_List = [];

            for i = 1:IntermediateHubs

                IH_List = [ IH_List IntermediateHub(i) ];

                IH = IH_List(i);
                IH.PU = rand(1)*1000;
                IH.RH_ID = RH.ID;
                IH.nodes_cluster_LH = nodes_cluster_LH; %used to compute the delay of Transmission
                IH.nodes_IH = IntermediateHubs;

            end

            LH_List = [];
            IH = 1;
            SM_List = [];
            SM_ID = 1;
            for l = 1:LeafHubs

                LH_List = [ LH_List LeafHub(l) ];
                              
                LH = LH_List(l);
                LH.PU = rand(1)*1000;
                LH.IH_ID = IH_List(IH).ID;
                LH.nodes_cluster_SM = SMART_METERS_CLUSTERS(l); %used to compute the delay of Transmission
                LH.nodes_cluster_LH = nodes_cluster_LH;                

                % discovering which IH the leaf hub will communicate
                div = mod(double(l), ( double(LeafHubs)/double(IntermediateHubs) ) );
                if div == 0 && IH ~= IntermediateHubs
                    IH = IH + 1;
                end
                
                
                for s = 1:SMART_METERS_CLUSTERS(l)
                    
                    SM_List = [ SM_List SmartMeter(s) ];
                    
                    SM = SM_List(SM_ID);  % SmartMeter(ID) - Obj
                    SM.PU = rand(1)*1000;
                    SM.Power=0;
                    SM.Consumption=0;
                    SM.Price = 0;
                    SM.LH_ID = LH.ID;
                    SM.nodes_cluster_SM = SMART_METERS_CLUSTERS(l);
                    
                    SM_ID = SM_ID + 1;
                    % discovering which LH the smart meter will communicate (was used when all the hubs had the same number os smart meters)
                    %div = mod(double(s), ( double(SmartMeters)/double(LeafHubs) ) );
                    %if div == 0 && LH ~= LeafHubs
                    %    LH = LH + 1;
                    %end
                    
                end

            end

        end
        
        function new_consumption = calcConsumptionSubstitution(consumption, MENSAL_CONSUMPTION, price)
            
            % we used a simplified version of CES model 'ln(Q/Qg) = a * ln(P/Pg) + b'
            % source: "Household response to dynamic pricing of electricity: a survey of 15 experiments." Ahmad Fariqui, Sanem Sergici
                                    
            daily_consumption = 0;
                        
            a = -1.0;
            b = 0; % additional consumption
            Pg = 1; % normal price
            
            for hour = 1:24
                Qg = consumption(hour);
                P = price(hour);
                if P == 0
                    P = 0.01; % Price should be positive to compute the substitution
                end
                Q(hour) = Qg * exp(a * log(P / Pg) + b);
                
                daily_consumption = Q(hour) + daily_consumption;
            end
                                    
            scale = (MENSAL_CONSUMPTION/1000) / daily_consumption;
            
            for hour = 1:24
                new_consumption(hour) = Q(hour) * scale;
            end
                        
        end
        
        function new_dispersion_hour = calcNewDispersion(dispersion_hour, new_consumption_hour, consumption)
            for i = 1:24
                factor = new_consumption_hour(i) / consumption(i);
                new_dispersion_hour(i) = dispersion_hour(i) * factor; 
            end
        end
        
        function [smater_meter_generation, smart_meter_generation_dispersion] = calcSMGeneration(individual_generation, generation_curve, generation_dispersion)
                                    
            scale = individual_generation/ sum(generation_curve);
            
            for hour = 1:24
                smater_meter_generation(hour) = generation_curve(hour) * scale;
                smart_meter_generation_dispersion(hour) = smater_meter_generation(hour) * generation_dispersion;
            end
                        
        end
        
        function calcPrice(hour, consumption, dispersion_hour, clean_generation_hour, CLEAN_ENERGY_DISPERSION, SMART_METERS_GENERATION, SM_INDIVIDUAL_GENERATION, SmartMeters, LeafHubs, IntermediateHubs, SM_List, LH_List, IH_List, RH, SM_COMMUNICATION_FAULT, NUMBER_SM_FAULT, mean_smart_meters_consumption, mean_smart_meters_generation, LH_COMMUNICATION_FAULT, mean_leaf_hub_index, mean_leaf_hub_consumption, mean_leaf_hub_power)
           
            %% sending generated energy and consumption to the RH to calculate the price            
                        
            for s= 1:SmartMeters
                
                % attributting a different generation or the mean individual generation to the smart meters
                [m, n] = size(SMART_METERS_GENERATION); % n = number of smart meters with different generation
                if s <= n
                    [clean_generation_SM, clean_energy_dispersion_SM] = Globals.calcSMGeneration(SMART_METERS_GENERATION(s), clean_generation_hour, CLEAN_ENERGY_DISPERSION);
                else
                    [clean_generation_SM, clean_energy_dispersion_SM] = Globals.calcSMGeneration(SM_INDIVIDUAL_GENERATION, clean_generation_hour, CLEAN_ENERGY_DISPERSION);
                end
                
                SM.Power = normrnd(clean_generation_SM(hour), clean_energy_dispersion_SM(hour)); %random Gauss
                                
                if SM.Power < 0 % all non-negative
                    SM.Power = 0;
                end
                
                
                SM = SM_List(s); % SmartMeter(ID)
                LH = SM.LH_ID; % LeafHub(ID)
                LH = LH_List(LH); % LeafHub

                SM.Consumption = consumption(hour); % consumption fixed; normrnd(consumption(hour), dispersion_hour(hour)); % random Gauss
                
                if SM.Consumption < 0 % all non-negative
                    SM.Consumption = 0;
                end
                
                if SM_COMMUNICATION_FAULT == 1 % changing the generation and consumption with the history
                    if s <= NUMBER_SM_FAULT
                        %SM.Consumption = mean_smart_meters_consumption(s,hour);
                        SM.Power = mean_smart_meters_generation(s,hour);
                    end
                end
                
                % storing the consumption and generation of the smart meter
                SM.ConsumptionHour(hour) = SM.Consumption;
                SM.PowerHour(hour) = SM.Power;

                SM.send(LH, LH.time); % each SM will send message packet to a LH
                % sequence of events in the nodes:
                % SmartMeter authenticate with the corresponding LeafHub -> SM.send, LH.receive, LH.authenticateSM, LH.send, SM.receive, SM.authenticate
                % SmartMeter send consumption and generation to LeafHub -> SM.send, LH.receive, LH.storePower
                
            end
            
            for l = 1:LeafHubs
                times_lh(l) = LH_List(l).time;
            end
            
            max_time_lh = max(times_lh); % getting the time for the last LH to receive a message
            
            for l = 1:LeafHubs
                IH_ID = LH_List(l).IH_ID; % IH ID
                IH = IH_List(IH_ID); % IH Obj
                
                LH_List(l).calcResultantIndex(hour); % calculating sustainability index, resultant consumption and power
                
                if LH_COMMUNICATION_FAULT == 1 % changing the generation and consumption with the history
                    if l == 1
                        LH_List(l).ResultantIndex = mean_leaf_hub_index(hour);
                        LH_List(l).ResultantPower = mean_leaf_hub_power(hour);
                        LH_List(l).ResultantConsumption = mean_leaf_hub_consumption(hour);
                    end
                end
                
                if IH.time == 0
                    IH.time = max_time_lh; % each IH has the initial time of the lastest LH to send a packet
                end
                LH_List(l).send(4, IH, IH.time); % each LH will send message packet to a IH
                % sequence of events in the nodes:
                % LeafHub authenticating with IntermediateHub -> LH.send, IH.receive, IH.authenticateLH, IH.send, LH.authenticateIH
                % sending resultant index, consumption and power to IntermediateHub -> LH.send, IH.receive, IH.storePower
                              
            end

            for i = 1:IntermediateHubs
                times_ih(i) = IH_List(i).time;
            end
            
            max_time_ih = max(times_ih); % lastest IH to send msg packet to RH
            
            RH.time = max_time_ih; % RH has the time of the lastest IH
            
            for i =1:IntermediateHubs
                IH_List(i).calcResultantIndex(); % calculating resultant index, generation and consumption
                IH_List(i).send(2, RH, RH.time);
                %sequence of events in the nodes:
                % authenticating to the RootHub and send message -> IH.send, RH.Receive, RH.storePower
                
            end

            RH.calcResultantIndex(hour); % calculates the resultant index, consumption, generation and right after the price
            
            %% RETURNING THE PRICE TO THE SMARTMETERS

            % Sending the price back to the IntermediateHubs
            line = size(RH.List_IH);
            for i = 1:line(1)
                IH_ID = RH.List_IH(i,1); % ID
                IH = IH_List(IH_ID); % Obj
                RH.send(2, IH, RH.time); % each IH will be updated with the RH time

                % Sending the price back to the LeafHubs
                line = size(RH.List_IH);
                for l = 1:line(1)
                    LH_ID = RH.List_IH(l,1); % ID
                    LH = LH_List(LH_ID); % Obj
                    RH.send(4, LH, IH.time); % each LH will be updated with the IH time

                    % Sending the price back to the SmartMeters
                    line = size(LH.List_SM);
                    for s = 1:line(1)
                        SM_ID = LH.List_SM(s,1); % ID
                        SM = SM_List(SM_ID); % Obj
                        LH.send(2, SM, LH.time); % each SM will be updated with the LH time
                    end

                end

            end
            
            
        end
        
        
    end
end
        
        
