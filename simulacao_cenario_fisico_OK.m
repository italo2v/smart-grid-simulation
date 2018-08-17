clc;

%% VARIAVEIS INICIAIS

mes = 10; % outubro 
SOL_EFICIENCIA = 22; % porcento
GERACAO_MENSAL_EOLICA = 10 * 1000; % KWh
GERACAO_MENSAL_SOLAR = 10 * 1000; % Wh
CONSUMO_MENSAL = 100 * 1000; % KWh ( 50 a 100 residencias de 100 a 200 kWh )
CONSUMO_CARGA = [0.28, 0.3, 0.24, 0.14, 0.15, 0.11, 0.3, 0.27, 0.27, 0.18, 0.24, 0.38, 0.27, 0.22, 0.22, 0.2, 0.59, 0.57, 0.65, 0.61, 0.53, 0.53, 0.53, 0.28];
CONSUMO_DISPERSAO = [0.2, 0.22, 0.18, 0.11, 0.09, 0.05, 0.18, 0.3, 0.18, 0.06, 0.19, 0.19, 0.16, 0.08, 0.1, 0.07, 0.75, 0.44, 0.4, 0.2, 0.2, 0.46, 0.4, 0.18];

MEDIA_CONSUMO_SM = 150; % kWh



SmartMeters = int32(CONSUMO_MENSAL/MEDIA_CONSUMO_SM);
LeafHubs = int32(SmartMeters/5);
IntermediateHubs = int32(LeafHubs/10);


%% CONSUMO

consumo_diario = sum(CONSUMO_CARGA);
consumo_escala = MEDIA_CONSUMO_SM / consumo_diario;

for i = 1:24
    consumo_hora(i) = CONSUMO_CARGA(i) * consumo_escala;
    dispersao_hora(i) = CONSUMO_DISPERSAO(i) * consumo_escala;
end



%% GERACAO EOLICA

%velocidade(m/s)
eol_velocidade_horas = [2.3859648705, 1.5, 1.894736886, 1.5438597202, 1.1929824352, 1.8596491814, 4.2105264664, 5.649122715, 6.2105264664, 6.2456140518, 5.7192983627, 5.4736843109, 5.2631578445, 5.1578946114, 5.29824543, 5.4736843109, 5.4035086632, 4.9473686218, 5.29824543, 5.8947367668, 5.8947367668, 5.2280702591, 4.4561405182, 3.649122715];
%fonte: atlas_eolico_PB.pdf (grafico 4b)
eol_velocidade_meses = [4.545454502, 3.606060743, 2.606060743, 2.818181992, 2.666666746, 2.484848499, 3.363636494, 3.363636494, 4.454545498, 5.818181992, 6.333333492, 5.454545498];
%fonte: atlas_eolico_PB.pdf (grafico 3b)


%potencia(Kw), 14 m/s em diante ? 2050
%fonte: arquivo27_31.pdf (figura 13)
eol_potencia_geracao = [0, 2, 18, 56, 127, 240, 400, 626, 892, 1223, 1590, 1830, 1950, 2050];
eol_pos = fix(eol_velocidade_horas);
for i=1:24
    if(eol_velocidade_horas(i) >= 14)
        eol_potencia_gerada(i) = 2050;
    elseif(eol_velocidade_horas(i) < 2)
        eol_potencia_gerada(i) = 0;
    else
        eol_potencia_gerada(i) = eol_potencia_geracao(eol_pos(i));
        %adicionando a fracao
        eol_intervalo = eol_potencia_geracao(eol_pos(i)+1)-eol_potencia_geracao(eol_pos(i));
        eol_fracao = eol_velocidade_horas(i)-eol_pos(i);
        eol_potencia_gerada(i) = eol_potencia_gerada(i)+(eol_fracao*eol_intervalo);
    end
end

eol_producao_diaria = sum(eol_potencia_gerada);

%ajustando para o mes
eol_mes_max = 11;
eol_escala = eol_velocidade_meses(mes) / eol_velocidade_meses(eol_mes_max);
eol_producao_diaria_desejada = GERACAO_MENSAL_EOLICA * eol_escala;
eol_escala = eol_producao_diaria_desejada / eol_producao_diaria;
for i = 1:24
    eol_potencia_gerada(i) = eol_potencia_gerada(i) * eol_escala;
end


%% GERACAO SOLAR

sol_irradiacao_hora = [0, 0, 0, 0, 0, 0.0708333403, 0.2166666836, 0.4416666925, 0.6625000238, 0.8375000358, 0.9541667104, 0.9958333969, 0.9875000715, 0.883333385, 0.7125000358, 0.508333385, 0.275000006, 0.1125000119, 0, 0, 0, 0, 0, 0];
%fonte: Alexandre dal Pai.pdf (grafico 4a)
sol_irradiacao_mes = [10.211268425, 10.0704231262, 12.6056346893, 13.380282402, 10.0704231262, 9.4366197586, 10.1408452988, 11.2676057816, 10.9154930115, 12.3943662643, 12.1126766205, 11.197183609];
%fonte: Alexandre dal Pai.pdf (grafico 6)
for i = 1:24
    sol_potencia_hora(i) = sol_irradiacao_hora(i)*SOL_EFICIENCIA/100;
end

sol_producao_diaria = sum(sol_potencia_hora);
sol_mes_max = 4;
sol_escala = sol_irradiacao_mes(mes) / sol_irradiacao_mes(sol_mes_max);
sol_producao_diaria_desejada = GERACAO_MENSAL_SOLAR * sol_escala;
sol_escala = sol_producao_diaria_desejada / sol_producao_diaria;

for i = 1:24
    sol_potencia_gerada(i) = sol_potencia_hora(i) * sol_escala;
end

%% CRIANDO OS NOS DO CENARIO

RH = RootHub(1);
RH.PU = 9678;


IH_List = [];
    
for i = 1:IntermediateHubs
    
    IH_List = [ IH_List IntermediateHub(i) ];

    IH = IH_List(i);
    IH.PU = rand(1)*1000;
    IH.RH_ID=1;
    
end

LH_List = [];
    
for l = 1:LeafHubs
    
    LH_List = [ LH_List LeafHub(l) ];
    
    IH = double(l) / (double(LeafHubs) / double(IntermediateHubs));
    if IH > int32(IH) && int32(IH) ~= IntermediateHubs
        IH = int32(IH) + 1;
    else
        IH = int32(IH);
    end
    
    LH = LH_List(l);
    LH.PU = rand(1)*1000;
    LH.IH_ID = IH;
    
end

SM_List = [];

for s = 1:SmartMeters

    SM_List = [ SM_List SmartMeter(s) ];
    
    LH = double(s) / (double(SmartMeters)/double(LeafHubs));
    if LH > floor(LH) && int32(LH) ~= LeafHubs
        LH = int32(LH) + 1;
    else
        LH = int32(LH);
    end

    SM = SM_List(s);  % SmartMeter(ID)
    SM.PU = rand(1)*1000;
    SM.Power=0;
    SM.Preco = 0;
    SM.LH_ID = LH;
    
end

%% fazendo o calculo do preco para cada hora h

geracao_limpa_hora = eol_potencia_gerada + sol_potencia_gerada;
for h = 1:24

    %limpando os indices para computar os precos nas horas diferentes
    for s = 1:SmartMeters
        SM_List(s).LH_PU=0;
    end
    for l = 1:LeafHubs
        LH_List(l).IH_PU=0;
        LH_List(l).List_SM=[];
    end
    for i = 1:IntermediateHubs
        IH_List(i).RH_PU=0;
        IH_List(i).List_LH=[];
    end
    RH.List_IH=[];
    
    
    %% ENVIANDO A ENERGIA GERADA AO RH

    Total = 0;
    for s= 1:SmartMeters
        SM = SM_List(s); % SmartMeter(ID)
        LH = SM.LH_ID; % LeafHub(ID)
        LH = LH_List(LH); % LeafHub Obj

        SM.Power = normrnd(consumo_hora(h), dispersao_hora(h)); % aleatorio Gauss
        %SM.Power = consumo_hora(h); % fixo
        if SM.Power < 0 % all non-negative
            SM.Power = 0;
        end

        if Total >= geracao_limpa_hora(h) % verificar se atingiu a quantidade de energia limpa na hora
            SM.Index = 1.22; % outubro
        else
            SM.Index = 0.07; % outubro
            Total = Total + SM.Power;
        end

        SM.enviar(LH); % autenticando e enviando msg ao LeafHub
    end

    for l = 1:LeafHubs
        IH = LH_List(l).IH_ID; % IH ID
        IH = IH_List(IH); % IH Obj

        LH_List(l).calcResultantIndex(); % calculando o indice e energia resultantes
        LH_List(l).enviar(4, IH); % autenticando e enviando msg ao IntermediateHub
    end

    for i =1:IntermediateHubs
        IH_List(i).calcResultantIndex(); % calculando o indice e energia resultantes
        IH_List(i).enviar(2, RH); % autenticando e enviando msg ao RootHub
    end

    RH.calcResultantIndex();
    consumo(h) = sum(RH.ResultantPower);
    preco(h) = RH.Preco;

    %% RETORNANDO O PRECO AOS SMs

    % Enviando o preco de volta aos IntermediateHubs
    line = size(RH.List_IH);
    for i = 1:line(1)
        IH = RH.List_IH(i,1); % ID
        IH = IH_List(IH); % Obj
        RH.enviar(2, IH);



        % Enviando o preco de volta aos LeafHubs
        line = size(IH.List_LH);
        for l = 1:line(1)
            LH = IH.List_LH(l,1); % ID
            LH = LH_List(LH); % Obj
            IH.enviar(4, LH);


            % Enviando o preco de volta aos SmartMeters
            line = size(LH.List_SM);
            for s = 1:line(1)
                SM = LH.List_SM(s,1); % ID
                SM = SM_List(SM); % Obj
                LH.enviar(2, SM);
            end

        end

    end

end

consumo = consumo/1000; % MW
figure
plot(consumo)
title('Consumo (MWh)')
xlabel('Hora')
ylabel('MWh')
axis([1 24 0 9])
figure
plot(preco)
title('Preco (%)')
xlabel('Hora')
ylabel('Preco (%)')
axis([1 24 0.2 1.3])

fprintf('Finish!')