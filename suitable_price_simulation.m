%% VARIAVEIS INICIAIS

mes = 10; % outubro 
GERACAO_MENSAL_EOLICA = 10 * 1000; % KWh
GERACAO_MENSAL_SOLAR = 10 * 1000; % KWh
CONSUMO_MENSAL = 100 * 1000; % KWh ( 500 a 1000 residencias de 100 a 200 kWh )
CONSUMO_CARGA = [0.28, 0.3, 0.24, 0.14, 0.15, 0.11, 0.3, 0.27, 0.27, 0.18, 0.24, 0.38, 0.27, 0.22, 0.22, 0.2, 0.59, 0.57, 0.65, 0.61, 0.53, 0.53, 0.53, 0.28];
CONSUMO_DISPERSAO = [0.2, 0.22, 0.18, 0.11, 0.09, 0.05, 0.18, 0.3, 0.18, 0.06, 0.19, 0.19, 0.16, 0.08, 0.1, 0.07, 0.75, 0.44, 0.4, 0.2, 0.2, 0.46, 0.4, 0.18];


ALIMENTADOR = [1698.778157906429, 1699.1424890034211, 1682.605411649709, 1649.1669258452926, 1657.9997334162704, 1683.7161771893188, 1760.127960190163, 2081.6190518505355, 2141.156084773626, 2166.8725285466744, 2133.4340427422576, 2133.789487714933, 2227.138223663749, 2286.648598213889, 2244.7594081841203, 2278.9265561825205, 2287.7682498778154, 2152.912427244857, 2516.648153907673, 2440.956146976496, 2230.0706446883187, 2044.5194828275646, 2053.334518149909, 1774.825609810281];
TRANSFORMADOR_2 = [8.51593625498008, 7.868525896414344, 7.569721115537849, 7.221115537848604, 7.02191235059761, 7.121513944223111, 7.569721115537849, 13.49601593625498, 14.741035856573705, 14.143426294820717, 14.342629482071713, 14.691235059760956, 14.691235059760956, 17.13147410358566, 17.03187250996016, 17.878486055776893, 18.725099601593627, 19.12350597609562, 21.165338645418327, 18.127490039840637, 15.587649402390438, 13.396414342629482, 13.047808764940239, 10.258964143426294];
CONSUMO_MENSAL = sum(ALIMENTADOR); % 49.0269 MW


MEDIA_CONSUMO_SM = 150; % kWh

LIMITE_SM_LIMPA = 100; % maximo de Smart Meters gerando energia Limpa

SMART_METERS = int32(CONSUMO_MENSAL/MEDIA_CONSUMO_SM); % order of a 1,000 to 10,000 meters each routing domain
LEAF_HUBS = 87; % int32(SmartMeters/10);  87 transformadores

INTERMEDIATE_HUBS = 10;%int32(LeafHubs/5);

GERACAO_MENSAL_EOLICA = CONSUMO_MENSAL * 0.25; % 25%
GERACAO_MENSAL_SOLAR = CONSUMO_MENSAL * 0.25; % 25%

%for ihs = 1:leafHubs
    

[consumo_hora, dispersao_hora] = Globals.calcula_consumo(CONSUMO_CARGA, CONSUMO_DISPERSAO, MEDIA_CONSUMO_SM);

% simulando 30 vezes para fazer as medias
%simulations = 30;
%for simulacao = 1:simulations

%% simulando os precos diferentes

j = 0;
%for preco_limpa = 0.5:0.01:1
%    for preco_hidro = 1.5:0.01:2
precos_limpa = [0.36, 0.30, 0.32, 0.29, 0.30, 0.28, 0.29, 0.34, 0.36, 0.41, 0.43, 0.32];
precos_suja = [1.39, 1.37, 1.37, 1.37, 1.28, 1.28, 1.32, 1.33, 1.39, 1.44, 1.46, 1.46];

        %% simulando os meses

        %meses = 12;
        %for mes = 1:meses
        %mes = 11;
        
        PRECO_HIDRO = precos_suja(mes);%preco_hidro; %1.95; 1.53 porcento
        PRECO_LIMPA = precos_limpa(mes);%preco_limpa; %0.84; 0.74 porcento

        [SM_List, LH_List, IH_List, RH] = Globals.create_nodes(SMART_METERS, LEAF_HUBS, INTERMEDIATE_HUBS, LIMITE_SM_LIMPA, PRECO_LIMPA, PRECO_HIDRO);

            month = mes;

            % calculando a geracao de energia limpa para cada mes
            eol_potencia_gerada = Globals.calcula_eolica(month, GERACAO_MENSAL_EOLICA);
            sol_potencia_gerada = Globals.calcula_solar(month, GERACAO_MENSAL_SOLAR);
            %[hidro_potencia_gerada, eol_potencia_gerada, sol_potencia_gerada] = calcula_hidro(eol_potencia_gerada, sol_potencia_gerada);
            geracao_limpa_hora = eol_potencia_gerada + sol_potencia_gerada;
            
        %for nd = 1:30 % 95% confidence interval

            % fazendo o calculo do preco para cada hora
            %for hora = 1:24
                Globals.calcula_preco(consumo_hora, dispersao_hora, geracao_limpa_hora, hora, LIMITE_SM_LIMPA, SMART_METERS, LEAF_HUBS, INTERMEDIATE_HUBS, SM_List, LH_List, IH_List, RH);
                
                for s = 1:SMART_METERS
                    times(s) = SM_List(s).time;
                    % zerando as contas para nao computar no lucro
                    SM_List(s).Conta = 0;
                    SM_List(s).ContaProtegida = 0;
                    % zerando o tempo para nao computar no delay
                    SM_List(s).time = 0;
                end
                for l = 1:LEAF_HUBS
                    LH_List(l).time = 0;
                end
                for i = 1:INTERMEDIATE_HUBS
                    IH_List(i).time = 0;
                end
                RH.time = 0;

                max_time = max(times);
                
                consumo = RH.ResultantConsumption/1000;
                energia_hidro_gerada = RH.ConsumoHidroeletrica/1000;
                preco = RH.Preco;
            %end
            
            %if mes == 1
            %    delay_auth = max_time(1)
            %    delay_normal = max_time(2)
            %    return;
            %end
            
            % CALCULANDO O CONSUMO APOS O PRECO
            consumo_hora_novo = Globals.calcula_novo_consumo(consumo_hora, MEDIA_CONSUMO_SM, preco);
            dispersao_hora_novo = Globals.calcula_nova_dispersao(dispersao_hora, consumo_hora_novo, consumo_hora);

            % refazendo o calculo do preco para cada hora
            for hora = 1:24

                Globals.calcula_preco(consumo_hora_novo, dispersao_hora_novo, geracao_limpa_hora, hora, LIMITE_SM_LIMPA, SMART_METERS, LEAF_HUBS, INTERMEDIATE_HUBS, SM_List, LH_List, IH_List, RH);
                
                consumo_novo(hora) = RH.ResultantConsumption/1000;
                energia_limpa_gerada(hora) = RH.ResultantPower/1000;
                energia_hidro_gerada_novo(hora) = RH.ConsumoHidroeletrica/1000;
                preco_novo(hora) = RH.Preco;

            end
            
            % contabilizando os bytes, pacotes enviados e lucros
            TotalConsumo = sum(consumo_novo);
            [KiloBytes, Packets, Lucro, LucroProtected] = Globals.calcula_lucro_packets_overhead(SMART_METERS, LEAF_HUBS, INTERMEDIATE_HUBS, SM_List, LH_List, IH_List, RH, MEDIA_CONSUMO_SM, TotalConsumo);

            
            % armazenando resultados do mes
            geracao_eolica(nd, 1:24) = eol_potencia_gerada;
            geracao_solar(nd, 1:24) = sol_potencia_gerada;
            geracao_limpa(nd, 1:24) = energia_limpa_gerada;
            geracao_hidro(nd, 1:24) = energia_hidro_gerada;
            geracao_hidro_novo(nd, 1:24) = energia_hidro_gerada_novo;
            diferenca_consumo_onpeak(nd) = sum(consumo(17:23)) - sum(consumo_novo(17:23));
            diferenca_consumo_offpeak(nd) = sum(consumo_novo(8:14)) - sum(consumo(8:14));
            precos(nd, 1:24) = preco;
            precos_novos(nd, 1:24) = preco_novo;
            consumos(nd, 1:24) = consumo;
            consumos_novos(nd, 1:24) = consumo_novo;
            lucros(nd) = Lucro;
            lucros_protected(nd) = LucroProtected;

        %end % nd

        % obtendo as medias e desvios para os resultados dos meses
        media_lucro(mes) = mean(lucros);
        desvio_lucro(mes) = std(lucros);
        media_lucro_protected(mes) = mean(lucros_protected);
        desvio_lucro_protected(mes) = std(lucros_protected);
        media_diferenca_on(mes) = mean(diferenca_consumo_onpeak);
        desvio_diferenca_on(mes) = std(diferenca_consumo_onpeak);
        media_diferenca_off(mes) = mean(diferenca_consumo_offpeak);
        desvio_diferenca_of(mes) = std(diferenca_consumo_offpeak);
        for i = 1:24
            media_precos(mes, i) = mean(precos(:, i));
            desvio1_precos(mes, i) = std(precos(:, i));
            media_precos_novos(mes, i) = mean(precos_novos(:, i));
            desvio1_precos_novos(mes, i) = std(precos_novos(:, i));
            media_consumos(mes, i) = mean(consumos(:, i));
            desvio1_consumos(mes, i) = std(consumos(:, i));
            media_consumos_novos(mes, i) = mean(consumos_novos(:, i));
            desvio1_consumos_novos(mes, i) = std(consumos_novos(:, i));
            media_geracao_limpa(mes, i) = mean(geracao_limpa(:, i));
            desvio_geracao_limpa(mes, i) = std(geracao_limpa(:, i));
            media_geracao_hidro(mes, i) = mean(geracao_hidro(:, i));
            desvio_geracao_hidro(mes, i) = std(geracao_hidro(:, i));
            media_geracao_hidro_novo(mes, i) = mean(geracao_hidro_novo(:, i));
            desvio_geracao_hidro_novo(mes, i) = std(geracao_hidro_novo(:, i));
        end
        hidro_max_peak(mes) = max(media_geracao_hidro_novo(17:23));
        hidro_max_off(mes) = max(media_geracao_hidro_novo(8:16));
    
        fprintf('Mes %f simulado!', mes);
        %end % meses

        %%aceitamos 2% de variacao do lucro
        %if media_lucro_protected >= 0.98 && media_lucro_protected <= 1.02
        %    %hidroeletrica fora do pico nao pode ultrapassar a hidroeletrica no pico
        %    if hidro_max_peak >= hidro_max_off
        %        j = j+1;
        %        limpa_geradas(1:24, j) = media_geracao_limpa;
        %        desvio_limpa_geradas(1:24, j) = desvio_geracao_limpa;
        %        hidro_geradas(1:24, j) = media_geracao_hidro;
        %        desvio_hidro_geradas(1:24, j) = desvio_geracao_hidro;
        %        hidro_geradas2(1:24, j) = media_geracao_hidro_novo;
        %        desvio_hidro_geradas2(1:24, j) = desvio_geracao_hidro_novo;
        %        variacoes_pico(j) = media_diferenca_on;
        %        desvio_variacoes_pico(j) = desvio_diferenca_on;
        %        variacoes_offpeak(j) = media_diferenca_off;
        %        desvio_variacoes_offpeak(j) = desvio_diferenca_off;
        %        max_hidro_offpeak(j) = hidro_max_off;
        %        max_hidro_onpeak(j) = hidro_max_peak;
        %        precos(1:24, j) = media_precos;
        %        desvio_precos(1:24, j) = desvio1_precos;
        %        precos_novos(1:24, j) = media_precos_novos;
        %        desvio_precos_novos(1:24, j) = desvio1_precos_novos;
        %        consumos(1:24, j) = media_consumos;
        %        desvio_consumos(1:24, j) = desvio1_consumos;
        %        consumos_novos(1:24, j) = media_consumos_novos;
        %        desvio_consumos_novos(1:24, j) = desvio1_consumos_novos;
        %        lucros(j) = media_lucro;
        %        desvio_lucros(j) = desvio_lucro;
        %        lucros_protected(j) = media_lucro_protected;
        %        desvio_lucros_protected(j) = desvio_lucro_protected;
        %        precos_energia(1:2, j) = [preco_limpa, preco_hidro];
        %        fprintf('Combinacao %d\n', j)
        %    end
        %end


        
%    end
%end % simulacao precos

fprintf('Finish!')
return;


%% exibindo o consumo no max reducao

clc;

%maximo = max(variacoes_pico);
%linha = find(maximo == variacoes_pico)


%for i = 1:24
%   
%   media_geracao_hidro(i) = media_consumos(i) - media_geracao_limpa(i);
%   if media_geracao_hidro(i) < 0
%       media_geracao_hidro(i) = 0;
%   end
%    
%end

%precos_energia(1:2, linha)
%variacoes_pico(linha)
%variacoes_offpeak(linha)

media_lucro
media_lucro_protected

media_diferenca_on
media_diferenca_off
mean(media_lucro)

for m = 1:12
reducao_suja(m) = sum(media_geracao_hidro(m, :)) - sum(media_geracao_hidro_novo(m, :));
end
reducao_suja

figure
%h = plot(1:24, media_precos(mes, 1:24));%, 1:24, media_precos_novos(mes, 1:24));
%h = plot(1:24, media_consumos(mes, 1:24), 1:24, media_geracao_limpa(mes, 1:24), 1:24, media_geracao_hidro(mes, 1:24));
h = plot(1:12, media_diferenca_on, 1:12, media_diferenca_off);
grid on
set(h, 'LineWidth', 2, 'Color', 'Black', 'MarkerSize', 20);
set(h(1), 'LineStyle', '-');%, 'Marker', '+');
set(h(2), 'LineStyle', '--');%, 'Marker', 'o');
%set(h(3), 'LineStyle', ':', 'Marker', 'x');
leg = legend('Consumption decrease on peak time', 'Consumption increase on off-peak time');
%leg = legend('Old consumption', 'Renewable energy generation', 'Fossil fuel energy generation');
%set(leg,'FontSize',30, 'Location', 'Best')
%axis([1 12 5 15]);
xlabel('Month')
ylabel('MWh')
set(gca,'FontSize', 24, 'FontWeight', 'Bold');
%figure
%errorbar(media_consumos_novos, desvio1_consumos_novos)
%% exibindo os as medias e desvios

% 1-4, 5-8, 9-12
clc;

figure
%hold on
%bpcombined = [media_consumos(:), media_consumos_novos(:), media_geracao_limpa(:), media_geracao_hidro(:), media_geracao_hidro_novo(:)];
%ebpcombined = [desvio1_consumos(:), desvio1_consumos_novos(:), desvio_geracao_limpa(:), desvio_geracao_hidro(:), desvio_geracao_hidro_novo(:)];
%errorbar(bpcombined, ebpcombined);
plot(1:24, media_consumos, 1:24, media_consumos_novos, 1:24, media_geracao_limpa, 1:24, media_geracao_hidro, 1:24, media_geracao_hidro_novo);
legend('consumo', 'consumo novo', 'geracao limpa', 'geracao hidro', 'geracao hidro nova');
%errorbar(geracao_limpa_months_1_4_mean, geracao_limpa_months_1_4_std, 'rx');
%h = errorbar(geracao_limpa_months_1_4_mean, geracao_limpa_months_1_4_std, 'rx');
%set(h, 'Color', 'Black');

%% exibindo resultados dos lucros

media_lucro_m(1:meses) = media_lucro;
media_lucro_protected_m(1:meses) = media_lucro_protected;

figure('Name', 'Lucros por mes')
h = plot(1:meses, lucros, 1:meses, lucros_protected, 1:meses, media_lucro_m, 1:meses, media_lucro_protected_m);
set(h, 'LineWidth', 2);
legend('Profit without protection', 'Profit with protection')
%axis([1 meses 0.95 1.15])
xlabel('Month')
ylabel('Profit (%)')
set(gca,'FontSize', 24, 'FontWeight', 'Bold');

%% exibindo os resultados das diferencas

figure('Name', 'Diferencas de Consumo')
h = plot(1:meses, diferenca_consumo_onpeak, 1:meses, diferenca_consumo_offpeak, 1:meses, media_diferenca_on, 1:meses, media_diferenca_off);
legend('Peak time decrease', 'Offpeak time increase')
set(h, 'LineWidth', 2);
xlabel('Month')
ylabel('MWh')
axis([1 meses 0 9])
set(gca,'FontSize', 24, 'FontWeight', 'Bold');

%% plotando resultados medio para os 12 meses

figure('Name', 'Media de Precos')
h = plot(1:24, media_precos, 1:24, media_precos_novos);
set(h, 'LineWidth', 2);
legend('Initial price', 'Price after consumption changes')
xlabel('Hour')
ylabel('Price (%)')
axis([1 24 0 1.3])
set(gca,'FontSize', 24, 'FontWeight', 'Bold');

figure('Name', 'Media de ConsumosXGeracao')
h = plot(1:24, media_consumos, 1:24, media_consumos_novos, 1:24, media_geracao_limpa, 1:24, media_geracao_hidro, 1:24, media_geracao_hidro_novo);
set(h, 'LineWidth', 2);
legend('Original consumption', 'New consumption', 'Clean generation', 'Original hydro-electric generation', 'New hydro-electric generation')
xlabel('Hour')
ylabel('MWh')
axis([1 24 0 5])
set(gca,'FontSize', 24, 'FontWeight', 'Bold');

%% plotando resultados para cada mes

mes = 10;

figure('Name', 'Precos')
h = plot(1:24, precos(mes,:), 1:24, precos_novos(mes,:));
set(h, 'LineWidth', 2);
legend('Initial price', 'Price after consumption changes')
xlabel('Hour')
ylabel('Price (%)')
axis([1 24 0 1.3])
set(gca,'FontSize', 24, 'FontWeight', 'Bold');


figure('Name', 'ConsumosXGeracao')
h = plot(1:24, consumos(mes,:), 1:24, consumos_novos(mes,:), 1:24, geracao_limpa(mes,:), 1:24, geracao_hidro(mes,:), 1:24, geracao_hidro_novo(mes,:));
set(h, 'LineWidth', 2);
legend('Original consumption', 'New consumption', 'Clean generation', 'Original hydro-electric generation', 'New hydro-electric generation')
title('Consumo (MWh)')
xlabel('Hora')
ylabel('MWh')
axis([1 24 0 5])
set(gca,'FontSize', 24, 'FontWeight', 'Bold');