% This simulation was made using MATLAB R2016b
% Italo C. Brito, Leonardo C. Ribeiro, Luci Pirmez, Luiz F. R. C. Carmo, Claudio C. Miceli
% Copyright 2018 - PPGI/UFRJ - LabNet - http://labnet.nce.ufrj.br/
% License: GNU GPLv3 http://www.gnu.org/licenses/gpl.html
% Please, if you use this code, reference us on: 

classdef SmartMeter < handle
    properties
        ID;
        PU;
        Index=0;
        Consumption;
        Power;
        Price=0;
        LH_ID=0;
        LH_PU=0;
        ConsumptionHour=[];
        PowerHour=[];
        time=0;
        nodes_cluster_SM=0;
        
    end
    methods
        function obj = SmartMeter(id)
            obj.ID = id;
        end
        
        function send(obj, LeafHub, Timestamp)

            SM_Signature = rand(1)*1000;
            
            if obj.LH_PU == 0
                
                RA_Signature = rand(1)*1000;
                type = 1; %auth
                
                packet = [type, double(obj.ID), double(LeafHub.ID), obj.Index, obj.PU, Timestamp, RA_Signature];
                %fprintf('SM %d sent auth packet to LH %d at time %d.\n', obj.ID, LeafHub.ID, Timestamp);
                LeafHub.receive(packet, obj);
            else
                type = 2; % msg
                packet = [type, double(obj.ID), double(LeafHub.ID), obj.Power, obj.Consumption, Timestamp, SM_Signature];
                %fprintf('SM %d sent msg packet to LH %d at time %d.\n', obj.ID, LeafHub.ID, Timestamp);
                LeafHub.receive(packet, obj);
            end
           
        end
        
        function receive(obj, packet, LeafHub)
            
            type = packet(1);
            SM_ID = packet(3);
            Timestamp = packet(5);
            
            if obj.ID ~= SM_ID
                return;
            end
            
            if type == 2 % msg
                %fprintf('SM %d received msg packet from LH %d at time %d.\n', obj.ID, packet(2), packet(5));
                obj.time = Timestamp +  Transmission.ZigBee_delay(27.5, obj.nodes_cluster_SM, 1);
                price = packet(4);
                obj.Price = price;
                    
            elseif type == 1 % auth
                %fprintf('SM %d received auth packet from LH %d at time %d.\n', obj.ID, packet(2), packet(5));
                obj.time = Timestamp +  Transmission.ZigBee_delay(47, obj.nodes_cluster_SM, 1);
                obj.authenticate(packet);
                obj.send(LeafHub, obj.time);
            end
        end
        
        function authenticate(obj,packet)
            
            LH_ID = packet(2);
            SM_ID = packet(3);
            LH_PU = packet(4);
            Timestamp = packet(5);
            RA_Signature = packet(6);
                    
            if obj.LH_ID == LH_ID && obj.LH_PU == 0
                obj.LH_PU = LH_PU;
            end
            
        end
        
        
    end
end
        
        
