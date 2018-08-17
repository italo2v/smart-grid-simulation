% This simulation was made using MATLAB R2016b
% Italo C. Brito, Leonardo C. Ribeiro, Luci Pirmez, Luiz F. R. C. Carmo, Claudio C. Miceli
% Copyright 2018 - PPGI/UFRJ - LabNet - http://labnet.nce.ufrj.br/
% License: GNU GPLv3 http://www.gnu.org/licenses/gpl.html
% Please, if you use this code, reference us on: 

clc;
%clear all;
slCharacterEncoding('UTF-8');
feature('DefaultCharacterSet','UTF8');

% INITIAL VARIABLES
% upper case = CONSTANT
% lower case = may vary on simulation


%% VARIABLES OF NETWORK SIMULATION

% this vector represents the number of Smart Meters connected to each Leaf Hub... *** MUST BE THE SIZE OF LEAF HUBS QUANTITY ***
SMART_METERS_CLUSTERS = [35, 29, 11, 23, 37, 59, 34, 20, 53, 26]; %(327 SM -> 150 Kwh per SM in 49 MWh scenario)
% number of Smart Meters
SMART_METERS = sum(SMART_METERS_CLUSTERS);
% number of Hubs
LEAF_HUBS = 10; % 87 transformers (the leaf hub could be at the transformer)
INTERMEDIATE_HUBS = int32(LEAF_HUBS/5);

%% VARIABLES OF MEAN HISTORY CALCULATION AND SUBSTITUTION ON ATTACK

DAYS = 30; % number of days to calculate the history

SM_COMMUNICATION_FAULT = 0; % 1 = on; 0 = off; simulate smart meters compromised (security attack, eg. DDoS)
NUMBER_SM_FAULT = 3; % number os smart meters compromised
LH_COMMUNICATION_FAULT = 1; % 1 = on; 0 = off; simulate leaf hub (data concentrator) compromised

%% VARIABLES OF THE FICTICIOUS SCENARIO

month = 11; % november (month of better clean energy generation according to the curves)

SM_CLEAN_LIMIT = 0; % used to limit the number of smart meters generating clean energy; 0 = off

% this vector represents the clean generation of each Smart Meter in the first Leaf Hub...
% the size of this vector corresponds of how much smart meters will have a different generation
SMART_METERS_GENERATION = [71.4137*2, 71.4137*1.5, 71.4137*1.25]; % 71.4137 mean generation per SM

% dispersion of clean energy generation to simulate the communication attack
CLEAN_ENERGY_DISPERSION = 0.15; % 25% of the clean energy generation

% actually simulating 50% of energy demand provided from wind and solar
WIND_MENSAL_GENERATION = 0.4;
SOLAR_MENSAL_GENERATION = 0.4;

% assign some prices to clean and dirty energy for each month (obtained from suitable_price_simulation.m)
% source: "Incentivando o Consumo de Energia Limpa Com Precifica??o Din?mica", In Portugueese, Italo Brito et al. (Table I)
% 30% clean energy generation
CLEAN_ENERGY_PRICES = [0.25, 0.15, 0.2, 0.24, 0.04, 0, 0.13, 0.2, 0.25, 0.24, 0.24, 0.25];
DIRTY_ENERGY_PRICES = [1.2, 1.2, 1.22, 1.22, 1.22, 1.18, 1.22, 1.23, 1.22, 1.27, 1.28, 1.27];
% 50% clean energy generation
%CLEAN_ENERGY_PRICES = [0.35, 0.31, 0.33, 0.32, 0.31, 0.28, 0.31, 0.34, 0.36, 0.4, 0.42, 0.36];
%DIRTY_ENERGY_PRICES = [1.36, 1.35, 1.34, 1.36, 1.29, 1.29, 1.34, 1.33, 1.41, 1.51, 1.52, 1.48];
% 80% clean energy generation
%CLEAN_ENERGY_PRICES = [0.47, 0.46, 0.43, 0.42, 0.45, 0.42, 0.46, 0.45, 0.47, 0.5, 0.5, 0.48];
%DIRTY_ENERGY_PRICES = [1.7, 1.58, 1.65, 1.71, 1.48, 1.42, 1.57, 1.65, 1.77, 2.2, 2.22, 1.92];


%% GRAPHS TO SHOW  (0 = off; 1 = on)

% normal scenario
GRAPH_LAST_DAY_CONSUMPTION_GENERATION_CURVES = 0;
GRAPH_LAST_DAY_PRICE = 0;

% normal scenario after consumption substitution
GRAPH_CURVES_AFTER_PRICE = 0;

% scenario under attack using mean history
GRAPH_NEW_CONSUMPTION_GENERATION_CURVES = 0;
GRAPH_NEW_PRICE = 0;

% curves without mean history and CES Applied
GRAPH_CONSUMPTION_SUBSTITUTION_NEW_PRICE = 0;
% curves with mean history and CES Applied
GRAPH_CONSUMPTION_SUBSTITUTION_OLD_PRICE = 0;

% price variation and standard deviation with and without mean history
GRAPH_PRICE_VARIATION = 0;
% difference between prices with and without mean history
GRAPH_PRICE_DIFFERENCE = 0;
% generation curves variation with and without mean history
GRAPH_CRUVES_VARIATION = 0;
% show price curves with and without mean history
GRAPH_OLD_NEW_PRICE = 0;


%% DECLARING SOME VARIABLES FOR THE SIMULATION

sum_consumptionVariation = zeros(1,24);
sum_generationVariation = zeros(1,24);
sum_hydroVariation = zeros(1,24);
sum_priceVariation = zeros(1,24);

sum_price = zeros(1,24);
sum_new_price = zeros(1,24);

sum_consumption = zeros(1,24);
sum_new_consumption = zeros(1,24);
sum_power = zeros(1,24);
sum_new_power = zeros(1,24);
sum_hydro = zeros(1,24);
sum_new_hydro = zeros(1,24);

mean_smart_meters_consumption = [];
mean_smart_meters_generation = [];
mean_leaf_hub_consumption = [];
mean_leaf_hub_power = [];
mean_leaf_hub_index = [];

sum_consumptionDifference = zeros(1,24);
sum_generationDifference = zeros(1,24);
sum_hydroDifference = zeros(1,24);
sum_priceDifference = zeros(1,24);

sum_after_consumption_old_price = 0;
sum_after_hydro_old_price = 0;
sum_dirty_consumption_reduction_old_price = 0;
sum_after_consumption_new_price = 0;
sum_after_hydro_new_price = 0;
sum_dirty_consumption_reduction_new_price = 0;
sum_difference_dirty_consumption_reduction = 0;
sum_variation_dirty_consumption_reduction = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% simulating the network communication (sending and receiving packets) to obtain the total delay and hydro generation curve %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[MENSAL_CONSUMPTION, CLUSTER_MENSAL_CONSUMPTION] = Globals.calcMensalConsumption();

SM_INDIVIDUAL_CONSUMPTION = MENSAL_CONSUMPTION/SMART_METERS; % kWh; each smart meter has the same consumption mean

WIND_MENSAL_GENERATION = MENSAL_CONSUMPTION * 0.25;
SOLAR_MENSAL_GENERATION = MENSAL_CONSUMPTION * 0.25;

[m, n] = size(SMART_METERS_GENERATION); % n = number of smart meter with different clean energy generation
% each smart meter generation energy of the following Smart Meters
SM_INDIVIDUAL_GENERATION = (WIND_MENSAL_GENERATION + SOLAR_MENSAL_GENERATION - sum(SMART_METERS_GENERATION)) / (SMART_METERS-n);

% returning the consumption curve for each smart meter
[consumption_hour, dispersion_hour] = Globals.calcConsumption(SM_INDIVIDUAL_CONSUMPTION);

%returning the list of smart meter, leaf hubs, intermediate hubs and the root hub
[SM_List, LH_List, IH_List, RH] = Globals.create_nodes(SMART_METERS_CLUSTERS, LEAF_HUBS, INTERMEDIATE_HUBS, int64(double(LEAF_HUBS)/double(INTERMEDIATE_HUBS)));

% calculating the clean energy generation for each month for each smart meter
wind_power_generated = Globals.calcWind(month, WIND_MENSAL_GENERATION);
solar_power_generated = Globals.calcSolar(month, SOLAR_MENSAL_GENERATION);
            
% calculating hydro generation (difference between clean energy generation and consumption)
% avoind here because is calculated in the network simulation at Root Hub
%hydro_power_generated = calcHydro(mean_power_generated, solar_power_generated);

% clean energy generation = WIND + SOLAR
clean_power_generation = wind_power_generated + solar_power_generated;

% returning the consumption curve for each smart meter
[consumption_hour, dispersion_hour] = Globals.calcConsumption(SM_INDIVIDUAL_CONSUMPTION);
clean_energy_dispersion = clean_power_generation * CLEAN_ENERGY_DISPERSION;

fprintf(' Solar energy: %f MWh. Wind Energy: %f MWh. Total clean energy: %f MWh. Consumption: %f MWh. \n', sum(solar_power_generated)/1000, sum(wind_power_generated)/1000, sum(clean_power_generation)/1000, sum(consumption_hour)*SMART_METERS/1000);
fprintf(' Starting simulation! \n Smart Meters: %d. Leaf Hubs: %d. Intermediate Hubs: %d. Number of LH connected to a IH: %d. \n', SMART_METERS, LEAF_HUBS, INTERMEDIATE_HUBS, double(LEAF_HUBS)/double(INTERMEDIATE_HUBS));

for nd = 1:30 % simulating 30 times to obtain 95% confidence interval
       
    %for month = 1:12 % simulating each month (just uncomment to simulate all the year) 
        
    %getting the price according to the selected month (hydro as dirty energy)
    HYDRO_PRICE = DIRTY_ENERGY_PRICES(month);
    CLEAN_PRICE = CLEAN_ENERGY_PRICES(month); 
    
    %n=1;
    %for HYDRO_PRICE = 1:0.01:2
    %for CLEAN_PRICE = 0.01:0.01:1
                
        % the hydro price is stored in the root hub once this node calculates the price
        RH.PriceHydro = HYDRO_PRICE;

        % using the sustainability index as the clean energy price
        for sm = 1:SMART_METERS
            SM_List(sm).Index = CLEAN_PRICE;
            if SM_CLEAN_LIMIT > 0
                if sm > SM_CLEAN_LIMIT % number of smart meter limit generating clean energy
                    SM_List(sm).Index = 0;
                else
                    SM_List(sm).Index = CLEAN_PRICE;
                end
            end
        end
        
        for days = 1:DAYS % simulating 30 days of consumption and generation
        
        for hour = 1:24 % simulating 24 hours of communication
            
                % used for the mean history
                for l = 1:LEAF_HUBS
                    LH_List(l).Day = days;
                end

                % calculating the energy price (simulation of sending packets from smart meters until root hub)
                Globals.calcPrice(hour, consumption_hour, dispersion_hour, clean_power_generation, CLEAN_ENERGY_DISPERSION, SMART_METERS_GENERATION, SM_INDIVIDUAL_GENERATION, SMART_METERS, LEAF_HUBS, INTERMEDIATE_HUBS, SM_List, LH_List, IH_List, RH, 0, 0, [], [], 0, [], [], []); % not computing the history yet
                
                % reseting the time to not compute on the total delay (because we are simulating many times, we need the delay of 1 hour)
                for s = 1:SMART_METERS
                    timonth(s) = SM_List(s).time; % last time of a packet price received by a smart meter
                    SM_List(s).time = 0;
                end
                for l = 1:LEAF_HUBS
                    LH_List(l).time = 0;
                end
                for ih = 1:INTERMEDIATE_HUBS
                    IH_List(ih).time = 0;
                end
                RH.time = 0;

                % getting the total delay to compute the price in the first and second hour simulation
                if hour <= 2
                    max_time(hour) = max(timonth); % last time of the last price packet receibed by a smart meter
                end
                
                % getting some results stored in the root hub
                price(hour) = RH.Price;
                consumption(hour) = RH.ResultantConsumption/1000;
                hydro_energy_generation(hour) = RH.ConsumptionHydro/1000;
                clean_energy_generation(hour) = RH.ResultantPower/1000;
                                
                % getting results of delay to compute the price calculation with and without authetication (first and second hours of simulation)
                if month == 1
                    delay_auth = max_time(1);
                    delay_normal = max_time(2);
                    %return;
                end
                
        
        end % hour
                
        %% calculating the new consumption and the energy generation according to the new price without mean history
        
        after_consumption_old_price = Globals.calcConsumptionSubstitution(consumption, MENSAL_CONSUMPTION, price);
        after_hydro_old_price = Globals.calcHydro(clean_energy_generation, after_consumption_old_price);
        
        dirty_consumption_reduction_old_price = sum(hydro_energy_generation) - sum(after_hydro_old_price);
                
        % discovering the suitable price
        %max_consumption_on_peak = max(consumption(17:23));
        %max_consumption_off_peak = max(consumption(1:16));
        %if max_consumption_on_peak > max_consumption_off_peak
        %    hydro_price(n) = HYDRO_PRICE;
        %    clean_price(n) = CLEAN_PRICE;
        %    difference_hydro(n) = sum(hydro_energy_generation) - sum(after_hydro_old_price);
        %end
        %n = n+1; 

        end % days
        
        
        if GRAPH_LAST_DAY_CONSUMPTION_GENERATION_CURVES == 1 && nd == 1 %show once
            % plotting the ficticious scenario curves for each month in the last day
            figure
            h = plot(1:24, consumption, 1:24, hydro_energy_generation, 1:24, clean_energy_generation);
            title(['Curves of Day ' num2str(days) ' - ' num2str(CLEAN_ENERGY_DISPERSION) ' clean energy dispersion - ' num2str( (WIND_MENSAL_GENERATION / MENSAL_CONSUMPTION)+(SOLAR_MENSAL_GENERATION / MENSAL_CONSUMPTION) ) ' Clean Energy Generation'])
            leg = legend('Consumption', 'Hydro Generation', 'Clean Generation');
            set(h, 'LineWidth', 2, 'MarkerSize', 20); %'Color', 'Black',);
            set(h(1), 'LineStyle', ':', 'Color', 'Black', 'Marker', '+');
            set(h(2), 'LineStyle', '--', 'Color', 'Red', 'Marker', 'x');
            set(h(3), 'LineStyle', '-', 'Color', 'Blue', 'Marker', 'o');
            set(leg, 'Location', 'Best')
            set(gca,'FontSize', 24, 'FontWeight', 'Bold');
            ylabel('MWh')
            xlabel('Hour')
            xlim([1 24])
            grid on
        end
        
        if GRAPH_LAST_DAY_PRICE == 1 && nd == 1 %show once
            % plotting the price curve for each month in the last day
            figure
            h = plot(price*100); % plotting on percentage
            title(['Prices of Day ' num2str(days) ' - ' num2str(CLEAN_ENERGY_DISPERSION) ' clean energy dispersion - ' num2str( (WIND_MENSAL_GENERATION / MENSAL_CONSUMPTION)+(SOLAR_MENSAL_GENERATION / MENSAL_CONSUMPTION) ) ' Clean Energy Generation'])
            set(h, 'LineWidth', 2, 'MarkerSize', 20); %'Color', 'Black',);
            set(gca,'FontSize', 24, 'FontWeight', 'Bold');
            ylabel('Price (%)')
            xlabel('Hour')
            xlim([1 24])
            grid on
        end
                
        if GRAPH_CURVES_AFTER_PRICE == 1 && nd == 1 %show once
            figure
            h = plot(1:24, after_consumption_old_price, 1:24, after_hydro_old_price, 1:24, clean_energy_generation);
            title(['Curves of Day ' num2str(days) ' - CES Model Applied'])
            leg = legend('Consumption After Old Price', 'Hydro Generation After Old Price', 'Clean Generation');
            set(h, 'LineWidth', 2, 'MarkerSize', 20); %'Color', 'Black',);
            set(h(1), 'LineStyle', ':', 'Color', 'Black', 'Marker', '+');
            set(h(2), 'LineStyle', '--', 'Color', 'Red', 'Marker', 'x');
            set(h(3), 'LineStyle', '-', 'Color', 'Blue', 'Marker', 'o');
            set(leg, 'Location', 'Best')
            set(gca,'FontSize', 24, 'FontWeight', 'Bold');
            ylabel('MWh')
            xlabel('Hour')
            xlim([1 24])
            grid on
        end
        
        %end %month
        
        fprintf(' Finalized the network simulation number %d for the price calculation process! \n', nd)
        %return; %uncomment to finish here
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% now we are going to simulate the communication attack and mean history %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % calculating the mean generation and consumption of smart meters for the history (STRATEGY WHEN SMART METER ATTACK OCCURS)
        
        if SM_COMMUNICATION_FAULT == 1
            
            LH = 1;
            for sm = 1:NUMBER_SM_FAULT
                
                % calculating the mean history of the smart meters from the leaf hub
                %mean_smart_meters_consumption(sm,:) = Globals.calcMeanHistory(LH_List(LH).History_Consumption_SM(s,:), DAYS);
                mean_smart_meters_generation(sm,:) = Globals.calcMeanHistory(LH_List(LH).History_Power_SM(sm,:), DAYS);
                
                % discovering which LH the smart meter is communicating
                div = mod(double(sm), ( double(SMART_METERS)/double(LEAF_HUBS) ) );
                if div == 0 && LH ~= LEAF_HUBS
                    LH = LH + 1;
                end
                
                % reaplacing the smart meters consumption and generation with the mean history
                %SM_List(sm).ConsumptionHour = mean_smart_meters_consumption(sm,:);
                SM_List(sm).PowerHour = mean_smart_meters_generation(sm,:);
                
            end
            
            fprintf(' Smart meters mean calculated and reaplaced the consumption and generation by the mean history! \n');
            
            % getting the history of smart meter 7
            %sm_7_consumption_mean = mean_smart_meters_consumption(7,:); % consumption mean of smart meter 7 when LH = 1
            %sm_7_consumption_mean = mean_smart_meters_generation(7,:); % generation mean of smart meter 7 when LH = 1
            
        end
        
        %% calculating the mean generation and consumption of leaf hubs for the history (STRATEGY WHEN LEAF HUB SECURITY FAULT OCCURS)
        
        if LH_COMMUNICATION_FAULT == 1 && SM_COMMUNICATION_FAULT == 1
            fprintf('Error: You cannot use both types of communication fault, please choose smart meter or data concentrador (LH) attack.');
            return;
        end
        if LH_COMMUNICATION_FAULT == 1
            
            sum_leaf_hub_consumption = zeros(24);
            sum_leaf_hub_index = zeros(24);
            sum_leaf_hub_power = zeros(24);             
            
            for day = 1:DAYS
                for hour = 1:24
                    sum_leaf_hub_consumption(hour) = sum_leaf_hub_consumption(hour) + LH_List(1).History_Consumption_LH(day, hour);
                    sum_leaf_hub_index(hour) = sum_leaf_hub_index(hour) + LH_List(1).History_Index_LH(day, hour);
                    sum_leaf_hub_power(hour) = sum_leaf_hub_power(hour) + LH_List(1).History_Power_LH(day, hour);
                end
            end
            for hour = 1:24
                mean_leaf_hub_consumption(hour) = sum_leaf_hub_consumption(hour)/DAYS;
                mean_leaf_hub_power(hour) = sum_leaf_hub_power(hour)/DAYS;
                mean_leaf_hub_index(hour) = sum_leaf_hub_index(hour)/DAYS;
            end
                       
            fprintf(' Leaf Hub 1 mean consumption, generation and index calculated and replaced by the mean history! \n');
        end
        
        % replacing by the consumption and generation mean of smart meters communicating to leaf hub 3
        %for sm = 1:10
        %SM = sm + 20;
        %SM_List(SM).ConsumptionHour = mean_smart_meters_consumption(sm,:); %SM_27_CONSUMPTION_MEAN;
        %SM_List(SM).PowerHour = mean_smart_meters_generation(sm,:); %SM_27_GENERATION_MEAN;
        %end
        
        %fprintf(' Reaplaced the consumption and generation of the smart meters communicating to Leaf Hub 3 by the mean history! \n');
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% recalculating the new consumption, generation and price using the mean history %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        for hour = 1:24 % simulating a new day as the smart meters with communication attack
            
            % calculating the energy price (simulation of sending packets from smart meters until root hub)
            Globals.calcPrice(hour, consumption_hour, dispersion_hour, clean_power_generation, CLEAN_ENERGY_DISPERSION, SMART_METERS_GENERATION, SM_INDIVIDUAL_GENERATION, SMART_METERS, LEAF_HUBS, INTERMEDIATE_HUBS, SM_List, LH_List, IH_List, RH, SM_COMMUNICATION_FAULT, NUMBER_SM_FAULT, mean_smart_meters_consumption, mean_smart_meters_generation, LH_COMMUNICATION_FAULT, mean_leaf_hub_index, mean_leaf_hub_consumption, mean_leaf_hub_power);
            
            % getting some results stored in the root hub
            new_consumption(hour) = RH.ResultantConsumption/1000;
            new_hydro_energy_generation(hour) = RH.ConsumptionHydro/1000;
            new_clean_energy_generation(hour) = RH.ResultantPower/1000;
            new_price(hour) = RH.Price;
            
            priceVariations(hour,nd) = ( double(new_price(hour)) - double(price(hour)) ) / double(price(hour));
            sum_priceVariation(hour) = sum_priceVariation(hour) +  priceVariations(hour,nd);
            
            %% doing summation of variables to compute mean generation, consumption and price
            sum_price(hour) = sum_price(hour) + price(hour);
            sum_new_price(hour) = sum_new_price(hour) + new_price(hour);
            
            sum_consumption(hour) = sum_consumption(hour) + consumption(hour);
            sum_new_consumption(hour) = sum_new_consumption(hour) + new_consumption(hour);
            sum_power(hour) = sum_power(hour) + clean_energy_generation(hour);
            sum_new_power(hour) = sum_new_power(hour) + new_clean_energy_generation(hour);
            sum_hydro(hour) = sum_hydro(hour) + hydro_energy_generation(hour);
            sum_new_hydro(hour) = sum_new_hydro(hour) + new_hydro_energy_generation(hour);   
            
        end % hour
        
        
        if GRAPH_NEW_CONSUMPTION_GENERATION_CURVES == 1 && nd == 1
            % plotting the ficticious scenario curves for each month with mean history
            figure
            h = plot(1:24, new_consumption, 1:24, new_hydro_energy_generation, 1:24, new_clean_energy_generation);
            title(['New Curves - ' num2str(CLEAN_ENERGY_DISPERSION) ' clean energy dispersion - ' num2str( (WIND_MENSAL_GENERATION / MENSAL_CONSUMPTION)+(SOLAR_MENSAL_GENERATION / MENSAL_CONSUMPTION) ) ' Clean Energy Generation - ' num2str(NUMBER_SM_FAULT) ' Smart Meters Fault - Mensal History'])
            leg = legend('Consumption', 'Hydro Generation', 'Clean Generation');
            set(h, 'LineWidth', 2, 'MarkerSize', 20); %'Color', 'Black',);
            set(h(1), 'LineStyle', ':', 'Color', 'Black', 'Marker', '+');
            set(h(2), 'LineStyle', '--', 'Color', 'Red', 'Marker', 'x');
            set(h(3), 'LineStyle', '-', 'Color', 'Blue', 'Marker', 'o');
            set(leg, 'Location', 'Best')
            set(gca,'FontSize', 24, 'FontWeight', 'Bold');
            ylabel('MWh')
            xlabel('Hour')
            xlim([1 24])
            grid on
        end
        
        if GRAPH_NEW_PRICE == 1 && nd == 1
            % plotting the price curve for each month with mean history
            figure
            h = plot(new_price*100); % plotting on percentage
            title(['New Prices - ' num2str(CLEAN_ENERGY_DISPERSION) ' clean energy dispersion - ' num2str( (WIND_MENSAL_GENERATION / MENSAL_CONSUMPTION)+(SOLAR_MENSAL_GENERATION / MENSAL_CONSUMPTION) ) ' Clean Energy Generation - ' num2str(NUMBER_SM_FAULT) ' Smart Meters Fault - Mensal History'])
            set(h, 'LineWidth', 2, 'MarkerSize', 20); %'Color', 'Black',);
            set(gca,'FontSize', 24, 'FontWeight', 'Bold');
            ylabel('Price (%)')
            xlabel('Hour')
            xlim([1 24])
            grid on
        end
        
        fprintf(' Calculated the variation of price, consumption and generation when using the mean history! \n');
        
        %return; % uncomment to stop here
        
        
        %% calculating the new consumption and the energy generation using the mean history
        
        after_consumption_new_price = Globals.calcConsumptionSubstitution(new_consumption, MENSAL_CONSUMPTION, new_price);
        after_hydro_new_price = Globals.calcHydro(new_clean_energy_generation, after_consumption_new_price);
        dirty_consumption_reduction_new_price = sum(new_hydro_energy_generation) - sum(after_hydro_new_price);
                
        sum_after_consumption_old_price = sum_after_consumption_old_price + after_consumption_old_price;
        sum_after_hydro_old_price = sum_after_hydro_old_price + after_hydro_old_price;
        sum_dirty_consumption_reduction_old_price = sum_dirty_consumption_reduction_old_price + dirty_consumption_reduction_old_price;
        
        sum_after_consumption_new_price = sum_after_consumption_new_price + after_consumption_new_price;
        sum_after_hydro_new_price = sum_after_hydro_new_price + after_hydro_new_price;
        sum_dirty_consumption_reduction_new_price = sum_dirty_consumption_reduction_new_price + dirty_consumption_reduction_new_price;
        sum_variation_dirty_consumption_reduction = sum_variation_dirty_consumption_reduction + ( (dirty_consumption_reduction_new_price - dirty_consumption_reduction_old_price) / dirty_consumption_reduction_old_price );
        
        for hour = 1:24
            
            % doing summations of the variations after CES applied with and without mean history
            sum_consumptionVariation(hour) = sum_consumptionVariation(hour) + ( double(after_consumption_new_price(hour)) - double(after_consumption_old_price(hour)) ) / double(after_consumption_old_price(hour));
            sum_generationVariation(hour) = sum_generationVariation(hour) + ( double(new_clean_energy_generation(hour)) - double(clean_energy_generation(hour)) ) / double(clean_energy_generation(hour));
            sum_hydroVariation(hour) = sum_hydroVariation(hour) + ( double(after_hydro_new_price(hour)) - double(after_hydro_old_price(hour)) ) / double(after_hydro_old_price(hour));
            
            % doing summations of the differences after CES applied with and without mean history
            sum_consumptionDifference(hour) = sum_consumptionDifference(hour) + double( after_consumption_new_price(hour) - after_consumption_old_price(hour) );
            sum_generationDifference(hour) = sum_generationDifference(hour) + double( new_clean_energy_generation(hour) - clean_energy_generation(hour) );
            sum_hydroDifference(hour) = sum_hydroDifference(hour) + double( after_hydro_new_price(hour) - after_hydro_old_price(hour) );
            sum_priceDifference(hour) = sum_priceDifference(hour) + double( new_price(hour) - price(hour) );
            
        end
                        
    %end
    %end
    
end % finish 30 times of simulation

    
%% calculating mean values ,variation and standard deviation

for hour = 1:24
    
    mean_after_consumption_old_price(hour) = sum_after_consumption_old_price(hour)/double(nd);
    mean_after_hydro_old_price(hour) = sum_after_hydro_old_price(hour)/double(nd);
    mean_dirty_consumption_reduction_old_price = sum_dirty_consumption_reduction_old_price/double(nd);
    
    mean_after_consumption_new_price(hour) = sum_after_consumption_new_price(hour)/double(nd);
    mean_after_hydro_new_price(hour) = sum_after_hydro_new_price(hour)/double(nd);
    mean_dirty_consumption_reduction_new_price = sum_dirty_consumption_reduction_new_price/double(nd);
    mean_variation_dirty_consumption_reduction = sum_variation_dirty_consumption_reduction/double(nd) * 100;
    
    % calculating the mean values    
    mean_price(hour) = sum_price(hour)/double(nd);
    mean_new_price(hour) = sum_new_price(hour)/double(nd);
    
    mean_consumption(hour) = sum_consumption(hour)/double(nd);
    mean_new_consumption(hour) = sum_new_consumption(hour)/double(nd);
    mean_power(hour) = sum_power(hour)/double(nd);
    mean_new_power(hour) = sum_new_power(hour)/double(nd);
    mean_hydro(hour) = sum_hydro(hour)/double(nd);
    mean_new_hydro(hour) = sum_new_hydro(hour)/double(nd);
        
    % getting mean variations on percentage
    consumptionVariation(hour) = sum_consumptionVariation(hour)/double(nd) * 100;
    generationVariation(hour) = sum_generationVariation(hour)/double(nd) * 100;
    hydroVariation(hour) = sum_hydroVariation(hour)/double(nd) * 100;
    priceVariation(hour) = sum_priceVariation(hour)/double(nd) * 100;
    
    % getting the mean difference between new and old consumption, hydro and clean generation, and price (%)
    
    consumptionDifference(hour) = sum_consumptionDifference(hour)/double(nd);
    generationDifference(hour) = sum_generationDifference(hour)/double(nd);
    hydroDifference(hour) = sum_hydroDifference(hour)/double(nd);
    priceDifference(hour) = sum_priceDifference(hour)/double(nd);
    
    if consumption(hour) == 0
        consumptionVariation(hour) = 0;
    end
    if clean_energy_generation(hour) == 0
        generationVariation(hour) = 0;
    end
    if hydro_energy_generation(hour) == 0
        hydroVariation(hour) = 0;
    end
    if price(hour) == 0
        priceVariation(hour) = 0;
    end
    
    sd_variation_price(hour) = std(priceVariations(hour,:));

end % hour

%% PLOTTING CURVES GRAPH AND WRITING MAX CLEAN ENERGY VARIATION AND HYDRO ENERGY GENERATION REDUCTION VARIATION

if GRAPH_CONSUMPTION_SUBSTITUTION_OLD_PRICE == 1 % without mean history
    figure
    h = plot(1:24, mean_after_consumption_old_price, 1:24, mean_after_hydro_old_price, 1:24, mean_power);
    leg = legend('Consumption', 'Hydro Generation', 'Clean Generation');
    set(h, 'LineWidth', 2, 'MarkerSize', 20); %'Color', 'Black',);
    set(h(1), 'LineStyle', ':', 'Color', 'Black', 'Marker', '+');
    set(h(2), 'LineStyle', '--', 'Color', 'Red', 'Marker', 'x');
    set(h(3), 'LineStyle', '-', 'Color', 'Blue', 'Marker', 'o');
    set(leg, 'Location', 'Best')
    set(gca,'FontSize', 24, 'FontWeight', 'Bold');
    title(['Curves with Consumption Substitution - ' num2str(CLEAN_ENERGY_DISPERSION) ' clean energy dispersion - ' num2str( (WIND_MENSAL_GENERATION / MENSAL_CONSUMPTION)+(SOLAR_MENSAL_GENERATION / MENSAL_CONSUMPTION) ) ' Clean Energy Generation - Without Mensal History'])
    ylabel('MWh')
    xlabel('Hour')
    xlim([1 24])
    grid on
end
if GRAPH_CONSUMPTION_SUBSTITUTION_NEW_PRICE == 1 % with mean history
    figure
    h = plot(1:24, mean_after_consumption_new_price, 1:24, mean_after_hydro_new_price, 1:24, mean_new_power);
    leg = legend('Consumption', 'Hydro Generation', 'Clean Generation');
    set(h, 'LineWidth', 2, 'MarkerSize', 20); %'Color', 'Black',);
    set(h(1), 'LineStyle', ':', 'Color', 'Black', 'Marker', '+');
    set(h(2), 'LineStyle', '--', 'Color', 'Red', 'Marker', 'x');
    set(h(3), 'LineStyle', '-', 'Color', 'Blue', 'Marker', 'o');
    set(leg, 'Location', 'Best')
    set(gca,'FontSize', 24, 'FontWeight', 'Bold');
    title(['Curves with Consumption Substitution - ' num2str(CLEAN_ENERGY_DISPERSION) ' clean energy dispersion - ' num2str( (WIND_MENSAL_GENERATION / MENSAL_CONSUMPTION)+(SOLAR_MENSAL_GENERATION / MENSAL_CONSUMPTION) ) ' Clean Energy Generation - ' num2str(NUMBER_SM_FAULT) ' Smart Meters Fault - Mensal History'])
    ylabel('MWh')
    xlabel('Hour')
    xlim([1 24])
    grid on
end

fprintf('The mean variation between the hydro energy generation reduction with and without mean history is: %.6f %%. \n', mean_variation_dirty_consumption_reduction*100); % getting on percentage
%fprintf('The max variation of clean energy generation was: %.6f %%. \n', max(generationVariation));


%% plotting the price variation with standard deviation of the hours variations
if GRAPH_PRICE_VARIATION == 1
    
    figure
    x = 1:1:24;
    e = errorbar(x, priceVariation, sd_variation_price);
    e.LineWidth = 1;
    grid on
    title(['Price variation of ' num2str(nd) ' simulations using ' num2str(CLEAN_ENERGY_DISPERSION) ' of clean energy dispersion - ' num2str(NUMBER_SM_FAULT) ' Smart Meters Fault - Mensal History'])
    set(e, 'LineWidth', 2, 'MarkerSize', 20); %'Color', 'Black',);
    set(gca,'FontSize', 24, 'FontWeight', 'Bold');
    ylabel('Variation (%)')
    xlabel('Hour')
    xlim([1 24])

end

%% plotting difference between prices
if GRAPH_PRICE_DIFFERENCE == 1
    
    figure
    h = plot(priceDifference);
    grid on
    leg = legend('Difference Between Prices in Normal Conditions and Under Attack');
    set(h, 'LineWidth', 2, 'MarkerSize', 20); %'Color', 'Black',);
    set(leg, 'Location', 'Best')
    set(gca,'FontSize', 24, 'FontWeight', 'Bold');
    ylabel('New Price - Old Price')
    xlabel('Hour')
    xlim([1 24])

end

%% plotting the veriations of consumption, hydro and clean generation
if GRAPH_CRUVES_VARIATION == 1
    
    figure
    h = plot(1:24, generationVariation, 1:24, hydroVariation); %, 1:24, consumptionVariation);
    grid on
    title(['Variations using ' num2str(CLEAN_ENERGY_DISPERSION) ' of clean energy dispersion - ' num2str(NUMBER_SM_FAULT) ' Smart Meters Fault - Mensal History'])
    leg = legend('Clean Energy Variation', 'Hydro Energy Variation'); %,'Consumption Variation');
    set(h, 'LineWidth', 2, 'MarkerSize', 20); %'Color', 'Black',);
    set(h(1), 'Color', 'Blue');%, 'Marker', 'o');
    set(h(2), 'Color', 'Red');%, 'Marker', 'x');
    %set(h(3), 'LineStyle', ':', 'Color', 'Black', 'Marker', '+');
    set(leg, 'Location', 'Best')
    set(gca,'FontSize', 24, 'FontWeight', 'Bold');
    ylabel('Variation (%)')
    xlabel('Hour')
    xlim([1 24])

end

%% plotting new and old prices
if GRAPH_OLD_NEW_PRICE == 1

    figure
    h = plot(1:24, mean_price, 1:24, mean_new_price);
    grid on
    leg = legend('Normal Price', 'Price Using History');
    set(h, 'LineWidth', 2, 'MarkerSize', 20); %'Color', 'Black',);
    set(h(1), 'LineStyle', '-');%, 'Color', 'Blue');%, 'Marker', '+');
    set(h(2), 'LineStyle', '--');%, 'Color', 'Red');%, 'Marker', 'o');
    set(leg, 'Location', 'Best')
    set(gca,'FontSize', 24, 'FontWeight', 'Bold');
    ylabel('Variation (%) from original')
    xlabel('Hour')
    xlim([1 24])

end

return;

%% script used to join different plots into subplots
clc;

name = 'curves_variation';

h1 = openfig(['GRAPHS\Attack_3_Smart_Meters_Different_Generation\' name '_25p_dispersion_50p_clean_energy.fig'],'reuse');
ax1 = gca; % get handle to axes of figure
h2 = openfig(['GRAPHS\Attack_Leaf_Hub\' name '_25p_dispersion_50p_clean_energy.fig'],'reuse'); % open figure
ax2 = gca;
%h3 = openfig('delays_6LoWPAN_LTE_160-256bits_ECC.fig','reuse'); % open figure
%ax3 = gca; % get handle to axes of figure
%h4 = openfig('delays_LTE_160-256bits_ECC.fig','reuse');
%ax4 = gca;
h5 = figure; %create new figure
s1 = subplot(2,2,1); %create and get handle to the subplot axes
% [x, y, width, height]
A = [0, 0, 0.5, 1];
set(gca, 'Position', A);
set(gca, 'OuterPosition', A);
grid(s1, 'minor');
s1.FontSize = 24;
s1.LineWidth = 2;
xlim(s1, [1 24]);
xlabel(s1, 'Hora');
ylabel(s1, 'Varia{\c{c}}{\~a}o (%)', 'interpreter','latex');
title(s1, 'Cen\''{a}rio A', 'interpreter','latex');
s2 = subplot(2,2,2);
% [x, y, width, height]
A = [0.5, 0, 0.54, 1];
set(gca, 'Position', A);
set(gca, 'OuterPosition', A);
grid(s2, 'minor');
s2.FontSize = 24;
s2.LineWidth = 2;
xlim(s2, [1 24]);
xlabel(s2, 'Hora');
ylabel(s2, 'Varia{\c{c}}{\~a}o (%)', 'interpreter','latex');
title(s2, 'Cen\''{a}rio B', 'interpreter','latex');
%s3 = subplot(2,2,3);
%s4 = subplot(2,2,4);
fig1 = get(ax1,'children'); %get handle to all the children in the figure
box(s1, 'on');
legend('on');
leg = legend(ax1, 'Gera{\c{c}\~a}o Limpa', 'Gera{\c{c}\~a}o Hidroel{\''e}trica');
set(leg, 'Location', 'Best');
set(leg, 'interpreter','latex');
set(leg, 'visible', 'on');
fig2 = get(ax2,'children');
box(s2, 'on');
legend('on');
leg = legend(ax2, 'Gera{\c{c}\~a}o Limpa', 'Gera{\c{c}\~a}o Hidroel{\''e}trica');
set(leg, 'Location', 'Best');
set(leg, 'interpreter','latex');
set(leg, 'visible', 'on');
%fig3 = get(ax3,'children');
%fig4 = get(ax4,'children');
copyobj(fig1,s1); %copy children to new parent axes i.e. the subplot axes
copyobj(fig2,s2);
%copyobj(fig3,s3);
%copyobj(fig4,s4);

x0=0;
y0=0;
width=1200;
height=450;
set(gcf,'units','points','position',[x0,y0,width,height]);
set(gcf, 'Position', [x0,y0,width,height]);
set(gcf, 'OuterPosition', [x0,y0,width,height]);

savefig(['GRAPHS\' name]);
print(['GRAPHS\' name], '-depsc');
close all;

return;

%% I could not show the lengend in the subplots, so I opened the .fig, inserted the legend and saved with this script in the correct size
clc;

name = 'price_variation';

h1 = openfig(['GRAPHS\' name '.fig'],'reuse');

x0=0;
y0=0;
width=1000;
height=450;
set(gcf,'units','points','position',[x0,y0,width,height])
set(gcf, 'Position', [x0,y0,width,height]);
set(gcf, 'OuterPosition', [x0,y0,width,height]);

savefig(['GRAPHS\' name]);
print(['GRAPHS\' name], '-depsc')
close all;
