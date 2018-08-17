% This simulation was made using MATLAB R2016b
% Italo C. Brito, Leonardo C. Ribeiro, Luci Pirmez, Luiz F. R. C. Carmo, Claudio C. Miceli
% Copyright 2018 - PPGI/UFRJ - LabNet - http://labnet.nce.ufrj.br/
% License: GNU GPLv3 http://www.gnu.org/licenses/gpl.html
% Please, if you use this code, reference us on: 

classdef LeafHub < handle
    properties
        ID;
        PU;
        ResultantIndex=0;
        ResultantPower=0;
        ResultantConsumption=0;
        Price=0;
        List_SM = [];
        History_Consumption_SM = [];
        History_Power_SM = [];
        History_Consumption_LH = [];
        History_Power_LH = [];
        History_Index_LH = [];
        Day=1;
        IH_ID=0;
        IH_PU=0;
        time=0;
        nodes_cluster_SM=0;
        nodes_cluster_LH=0;
        col = 1;
    end
    methods
        function obj = LeafHub(id)
            obj.ID = id;
        end
        
        function receive(obj, packet, Source)
            
            type = packet(1);
            LH_ID = packet(3);
            Timestamp = packet(6);
                
            if obj.ID ~= LH_ID
                return;
            end
            
            if type == 2 % msg SM
                %fprintf('LH %d received msg packet from SM %d at time %d.\n', obj.ID, packet(2), packet(6));
                obj.storePower(packet);
                obj.time = Timestamp +  Transmission.ZigBee_delay(31, obj.nodes_cluster_SM, 1);
            elseif type == 1 % auth SM
                %fprintf('LH %d received auth packet from SM %d at time %d.\n', obj.ID, packet(2), packet(6));
                obj.authenticateSM(packet);
                obj.time = Timestamp +  Transmission.ZigBee_delay(47.5, obj.nodes_cluster_SM, 1);
                obj.send(1, Source, obj.time);
            elseif type == 3 % auth IH
                %fprintf('LH %d received auth packet from IH %d at time %d.\n', obj.ID, packet(2), packet(5));
                obj.authenticateIH(packet);
                Timestamp = packet(5);
                obj.time = Timestamp +  Transmission.PLC_delay(47, obj.nodes_cluster_LH, 0);
                obj.send(4, Source, obj.time); % msg
            elseif type == 4 % msgprice
                %fprintf('LH %d received msg packet from IH %d at time %d.\n', obj.ID, packet(2), packet(5));
                Timestamp = packet(5);
                obj.time = Timestamp +  Transmission.PLC_delay(27.5, obj.nodes_cluster_LH, 0);
                price = packet(4);
                obj.Price = price;
            end
            
        end 
        
        function send(obj, type, Dest, Timestamp)
            
            RA_Signature = rand(1)*1000;
            LH_Signature = rand(1)*1000;
            
            if type == 4 % msg
                
                if obj.IH_PU == 0 % auth
                    packet = [3, double(obj.ID), double(Dest.ID), obj.PU, Timestamp, RA_Signature];
                    %fprintf('LH %d sent auth packet to IH %d at time %d.\n', obj.ID, Dest.ID, Timestamp);    
                    Dest.receive(packet, obj);
                else % msg
                    packet = [4, double(obj.ID), double(Dest.ID), obj.ResultantIndex, obj.ResultantPower, obj.ResultantConsumption, Timestamp, LH_Signature];
                    %fprintf('LH %d sent msg packet to IH %d at time %d.\n', obj.ID, Dest.ID, Timestamp);
                    Dest.receive(packet, obj);
                
                end
            
            elseif type == 1 % auth SM
            
                packet = [type, double(obj.ID), double(Dest.ID), obj.PU, Timestamp, RA_Signature];
                %fprintf('LH %d sent auth packet to SM %d at time %d.\n', obj.ID, Dest.ID, Timestamp);
                Dest.receive(packet, obj);
            elseif type == 2 % msgprice
            
                packet = [type, double(obj.ID), double(Dest.ID), obj.Price, Timestamp, RA_Signature];
                %fprintf('LH %d sent msg packet to SM %d at time %d.\n', obj.ID, Dest.ID, Timestamp);    
                Dest.receive(packet, obj);
            end
        end
        
        function authenticateSM(obj, packet)
                SM_ID = packet(2);
                LH_ID = packet(3);
                SM_Index = packet(4);
                SM_PU = packet(5);
                Timestamp = packet(6);
                RA_Signature = packet(7);
                
                if isempty(obj.List_SM) || ~ any(SM_ID == obj.List_SM(:,1)) % armazena index, PU e ID do SM
                    obj.List_SM = [obj.List_SM; SM_ID, SM_Index, SM_PU, 0, 0];
                end
                
        end
                
        function authenticateIH(obj, packet)
            
                IH_ID = packet(2);
                LH_ID = packet(3);
                IH_PU = packet(4);
                Timestamp = packet(5);
                RA_Signature = packet(6);
                
                if LH_ID ~= obj.ID
                    return;
                end
                
                if obj.IH_PU == 0
                    obj.IH_PU = IH_PU;
                end
                
        end
        
        function storePower(obj, packet)
            SM_ID = packet(2);
            LH_ID = packet(3);
            SM_Power = packet(4);
            SM_Consumption = packet(5);
            Timestamp = packet(6);
            SM_Signature = packet(7);
            
            
            [row, col] = size(obj.List_SM);
            qtde_SM = row;
            
            line = find(obj.List_SM(:,1) == SM_ID);
            obj.List_SM(line, 4) = SM_Power;
            obj.List_SM(line, 5) = SM_Consumption;
            
            %if obj.List_SM(line) == []
            obj.History_Consumption_SM(line, obj.col) = SM_Consumption;
            obj.History_Power_SM(line, obj.col) = SM_Power;
            if mod(SM_ID, 10) == 0
                obj.col = obj.col + 1;
            end
            
        end
        
        function calcResultantIndex(obj, hora)
            
            RP = sum(obj.List_SM(:,4));
            RC = sum(obj.List_SM(:,5));
            indexes = obj.List_SM(:,2);
            
            line = size(indexes);
            
            RI = 0;
            if RP > 0
                for i = 1:line(1)
                    power = obj.List_SM(i,4);
                    prop = power / RP;
                    RI = RI + ( prop * indexes(i) );
                end
            end
            
            obj.ResultantIndex = RI;
            obj.ResultantPower = RP;
            obj.ResultantConsumption = RC;
            
            obj.History_Index_LH(obj.Day, hora) = RI;
            obj.History_Power_LH(obj.Day, hora) = RP;
            obj.History_Consumption_LH(obj.Day, hora) = RC;
            
        end
        
    end
end
        
        
