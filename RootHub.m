% This simulation was made using MATLAB R2016b
% Italo C. Brito, Leonardo C. Ribeiro, Luci Pirmez, Luiz F. R. C. Carmo, Claudio C. Miceli
% Copyright 2018 - PPGI/UFRJ - LabNet - http://labnet.nce.ufrj.br/
% License: GNU GPLv3 http://www.gnu.org/licenses/gpl.html
% Please, if you use this code, reference us on: 

classdef RootHub < handle
    properties
        ID=1;
        PU;
        ResultantIndex=0;
        ResultantPower=0;
        ResultantConsumption=0;
        Price=0;
        List_IH = [];
        PriceHydro=0;
        ConsumptionHydro;
        time=0;
        nodes_IH=0;
    end
    methods
        function obj = RootHub(id)
            obj.ID = id;
        end
        
        function send(obj, type, Dest, Timestamp)
            
            RA_Signature = rand(1)*1000;
            IH_Signature = rand(1)*1000;
            
            if type == 1 % auth IH
                
                packet = [type, double(obj.ID), double(Dest.ID), obj.PU, Timestamp, RA_Signature];
                %fprintf('RH %d sent auth packet to IH %d at time %d.\n', obj.ID, Dest.ID, Timestamp);    
                Dest.receive(packet, obj);
            
            elseif type == 2 % msgPrice
            
                packet = [type, double(obj.ID), double(Dest.ID), obj.Price, Timestamp, RA_Signature];
                %fprintf('RH %d sent msg packet to IH %d at time %d.\n', obj.ID, Dest.ID, Timestamp);    
                Dest.receive(packet, obj);
            end
        end
        
        function receive(obj, packet, Source)
            
            type = packet(1);
            IH_ID = packet(3);
                
            if obj.ID ~= IH_ID
                return;
            end
            
            if type == 2 % msg IH
                %fprintf('RH %d received msg packet from IH %d at time %d.\n', obj.ID, packet(2), packet(7));
                obj.storePower(packet);
                Timestamp = packet(7);
                obj.time = Timestamp +  Transmission.PLC_delay(31.5, obj.nodes_IH, 0);
            elseif type == 1 % auth IH
                %fprintf('RH %d received auth packet from IH %d at time %d.\n', obj.ID, packet(2), packet(5));
                obj.authenticateIH(packet);
                Timestamp = packet(5);
                obj.time = Timestamp +  Transmission.PLC_delay(47, obj.nodes_IH, 0);
                obj.send(1, Source, obj.time);
            end
            
        end 
        
        function authenticateIH(obj, packet)
            
                IH_ID = packet(2);
                RH_ID = packet(3);
                IH_PU = packet(4);
                Timestamp = packet(5);
                RA_Signature = packet(6);
                
                
                if isempty(obj.List_IH) || ~ any(IH_ID == obj.List_IH(:,1)) % armazena ID e PU do LH
                    obj.List_IH = [obj.List_IH; IH_ID, IH_PU, 0, 0, 0];
                end
                
        end
                
        function storePower(obj, packet)
            IH_ID = packet(2);
            RH_ID = packet(3);
            ResultantIndex = packet(4);
            ResultantPower = packet(5);
            ResultantConsumption = packet(6);
            Timestamp = packet(7);
            SM_Signature = packet(8);
            
            
            line = find(obj.List_IH(:,1) == IH_ID);
            obj.List_IH(line, 3) = ResultantIndex;
            obj.List_IH(line, 4) = ResultantPower;
            obj.List_IH(line, 5) = ResultantConsumption;
            
        end
        
        function calcResultantIndex(obj, hora)
            
            RP = sum(obj.List_IH(:,4));
            RC = sum(obj.List_IH(:,5));
            indexes = obj.List_IH(:,3);
            
            line = size(indexes);
            
            RI = 0;
            if RP > 0
                for i = 1:line(1)
                    power = obj.List_IH(i,4);
                    prop = power / RP;
                    RI = RI + ( prop * indexes(i) );
                end
            end
            
            obj.ResultantIndex = RI;
            obj.ResultantPower = RP;
            obj.ResultantConsumption = RC;
            
            RH = RC - RP; % hydro
            if RH < 0
                RH = 0;
                RP = RC;
            end
            
            obj.ConsumptionHydro = RH;
            
            pc = RP / RC; % clean energy proportion 
            ph = RH / RC; % hydro energy proportion
            
            
            obj.Price = pc * RI + ph * obj.PriceHydro; % using the resultant index as the clean energy price
        end
        
    end
end
        
        
