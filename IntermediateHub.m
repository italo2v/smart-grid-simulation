% This simulation was made using MATLAB R2016b
% Italo C. Brito, Leonardo C. Ribeiro, Luci Pirmez, Luiz F. R. C. Carmo, Claudio C. Miceli
% Copyright 2018 - PPGI/UFRJ - LabNet - http://labnet.nce.ufrj.br/
% License: GNU GPLv3 http://www.gnu.org/licenses/gpl.html
% Please, if you use this code, reference us on: 

classdef IntermediateHub < handle
    properties
        ID;
        PU;
        ResultantIndex=0;
        ResultantPower=0;
        ResultantConsumption=0;
        Price=0;
        List_LH = [];
        RH_ID=1;
        RH_PU=0;
        time = 0;
        nodes_cluster_LH=0;
        nodes_IH=0;
    end
    methods
        function obj = IntermediateHub(val)
            obj.ID = val;
        end
                
        function receive(obj, packet, Source)
            
            type = packet(1);
            IH_ID = packet(3);
                
            if obj.ID ~= IH_ID
                return;
            end
            
            if type == 4 % msg LH
                %fprintf('IH %d received msg packet from LH %d at time %d.\n', obj.ID, packet(2), packet(7));
                obj.storePower(packet);
                Timestamp = packet(7);
                obj.time = Timestamp +  Transmission.PLC_delay(31.5, obj.nodes_cluster_LH, 0);
            elseif type == 3 % auth LH
                %fprintf('IH %d received auth packet from LH %d at time %d.\n', obj.ID, packet(2), packet(5));
                obj.authenticateLH(packet);
                Timestamp = packet(5);
                obj.time = Timestamp +  Transmission.PLC_delay(47, obj.nodes_cluster_LH, 0);
                obj.send(3, Source, obj.time);
            elseif type == 1 % auth RH
                %fprintf('IH %d received auth packet from RH %d at time %d.\n', obj.ID, packet(2), packet(5));
                obj.authenticateRH(packet);
                Timestamp = packet(5);
                obj.time = Timestamp +  Transmission.PLC_delay(47, obj.nodes_IH, 0);
                time_auth_rh = obj.time;
                obj.send(2, Source, obj.time); % msg
            elseif type == 2 % msgprice
                %fprintf('IH %d received msg packet from RH %d at time %d.\n', obj.ID, packet(2), packet(5));
                price = packet(4);
                Timestamp = packet(5);
                obj.time = Timestamp +  Transmission.PLC_delay(27.5, obj.nodes_IH, 0);
                time_msg_rh = obj.time;
                obj.Price = price;
            end
            
        end 
        
        function send(obj, type, Dest, Timestamp)
            
            RA_Signature = rand(1)*1000;
            IH_Signature = rand(1)*1000;
            
            if type == 2 % msg
                
                if obj.RH_PU == 0 % auth RH
                    packet = [1, double(obj.ID), double(Dest.ID), obj.PU, Timestamp, RA_Signature];
                    %fprintf('IH %d sent auth packet to RH %d at time %d.\n', obj.ID, Dest.ID, Timestamp);
                    Dest.receive(packet, obj);
                else % msg RH
                    packet = [2, double(obj.ID), double(Dest.ID), obj.ResultantIndex, obj.ResultantPower, obj.ResultantConsumption, Timestamp, IH_Signature];
                    %fprintf('IH %d sent msg packet to RH %d at time %d.\n', obj.ID, Dest.ID, Timestamp);
                    Dest.receive(packet, obj);
                end
            
            elseif type == 3 % auth LH
            
                packet = [type, double(obj.ID), double(Dest.ID), obj.PU, Timestamp, RA_Signature];
                %fprintf('IH %d sent auth packet to LH %d at time %d.\n', obj.ID, Dest.ID, Timestamp);    
                Dest.receive(packet, obj);
                
            elseif type == 4 % msgprice
            
                packet = [type, double(obj.ID), double(Dest.ID), obj.Price, Timestamp, RA_Signature];
                %fprintf('IH %d sent msg packet to LH %d at time %d.\n', obj.ID, Dest.ID, Timestamp);    
                Dest.receive(packet, obj);
            end
        end
        
        function authenticateLH(obj, packet)
            
                LH_ID = packet(2);
                IH_ID = packet(3);
                LH_PU = packet(4);
                Timestamp = packet(5);
                RA_Signature = packet(6);
                
                
                if isempty(obj.List_LH) || ~ any(LH_ID == obj.List_LH(:,1)) % armazena ID e PU do LH
                    obj.List_LH = [obj.List_LH; LH_ID, LH_PU, 0, 0, 0];
                end
                
        end
        
        function authenticateRH(obj, packet)
            
                RH_ID = packet(2);
                IH_ID = packet(3);
                RH_PU = packet(4);
                Timestamp = packet(5);
                RA_Signature = packet(6);
                
                
                if obj.RH_PU == 0
                    obj.RH_PU = RH_PU;
                end
        end
        
        function storePower(obj, packet)
            LH_ID = packet(2);
            IH_ID = packet(3);
            ResultantIndex = packet(4);
            ResultantPower = packet(5);
            ResultantConsumption = packet(6);
            Timestamp = packet(7);
            SM_Signature = packet(8);
            
            line = find(obj.List_LH(:,1) == LH_ID);
            obj.List_LH(line, 3) = ResultantIndex;
            obj.List_LH(line, 4) = ResultantPower;
            obj.List_LH(line, 5) = ResultantConsumption;
        end
                
        function calcResultantIndex(obj)
                        
            RP = sum(obj.List_LH(:,4));
            RC = sum(obj.List_LH(:,5));
            indexes = obj.List_LH(:,3);
            
            line = size(indexes);
            
            RI = 0;
            if RP > 0
                for i = 1:line(1)
                    power = obj.List_LH(i,4);
                    prop = power / RP;
                    RI = RI + ( prop * indexes(i) );
                end
            end
            
            obj.ResultantIndex = RI;
            obj.ResultantPower = RP;
            obj.ResultantConsumption = RC;
            
        end
        
    end
end
        
        
