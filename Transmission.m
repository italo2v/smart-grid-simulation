classdef Transmission < handle
    properties (Constant)
        key_size = 4;
    end
    
    methods(Static)
        
        function delay = delay_ECC(mode) % 1=assign, 2=verify_signature
            % source: "Towards quantifying the cost of a secure IoT: Overhead and energy consumption of ECC signatures on an ARM-based device." Mossinger, M. et al.
            
            %mode 1 = sign, mode 2 = verify
            %key_size 1 = 160, 2 = 192, 3 = 224, 4 = 256
            ECC_signatures = [0.211, 0.206, 0.297, 0.467]; %sign 160, 192, 224, 256
            ECC_verify = [0.225, 0.224, 0.324, 0.476]; %veryfy sign
            
            if mode == 1
                delay = ECC_signatures(Transmission.key_size);
            elseif mode == 2
                delay = ECC_verify(Transmission.key_size);
            end
            
        end
        
        function delay = LTE_delay(packet_size, nodes, processing) %bytes
            
            % source: Simulations using LTE-Sim (https://github.com/lte-sim/lte-sim-dev)
            % "Simulating LTE Cellular Systems: an Open Source Framework." Giuseppe Piro et al.
            
            %nodes = 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000
            delay_27_5B_DL = [0.00151, 0.00153, 0.00151, 0.00152, 0.00152, 0.00152, 0.00153, 0.00152, 0.00154, 0.00157];
            delay_31B_UL = [0.00153, 0.00173, 0.00792, 0.0197, 0.02908, 0.03727, 0.04, 0.03754, 0.03634, 0.03607];
            
            PLR_UL = [0, 0, 0, 0.003, 0.037, 0.092, 0.194, 0.353, 0.433, 0.494]; % Packet Loss Rate UpLink
            PLR_DL = 0; % Packet Loss Rate DownLink
            
            if nodes < 100
                nodes = 1;
            end
            
            if packet_size == 31
                PLR = 0;
                delay_signature = Transmission.delay_ECC(1);
                TX_delay = delay_31B_UL(nodes);
            elseif packet_size == 27.5
                PLR = PLR_UL(nodes);
                delay_signature = Transmission.delay_ECC(2);
                TX_delay = delay_27_5B_DL(nodes);
            else
                PLR = 0;
                delay_signature = Transmission.delay_ECC(1);
                TX_delay = delay_31B_UL(nodes);
            end
            
            retransmissions = 1 + PLR;
            if processing == 1
                delay = ( TX_delay + delay_signature ) * retransmissions;
            else
                delay = TX_delay * retransmissions;
            end
            
            % source: "Performance Comparison Study of ECC and AES in Commercial and Research Sensor Nodes." Piedra, A. et al.
            delay = delay + 0.148; % ECC performance 12 MHz in sensor node to encrypt/decrypt
            
        end
        
        function delay = ZigBee_delay(packet_size, nodes, processing) %bytes
            
            % maximum of 25 nodes per cluster, because the latency would increase too much
            if nodes > 25
                nodes = 25;
            end
            
            % source: "A Joint Model for IEEE 802.15.4 Physical and Medium Access Control Layers." Zayani, M. et al.
            
            % max distance = 50m
            delay_31b = [0.0136, 0.0142, 0.0150, 0.0159, 0.0170, 0.0179, 0.0187, 0.0194, 0.0199, 0.0204, 0.0208, 0.0211 0.0214, 0.0216, 0.0218, 0.0220, 0.0222, 0.0223, 0.0225, 0.0226, 0.0227, 0.0228, 0.0229, 0.0230 0.0231];
            delay_27_5b = [0.0133, 0.0138, 0.0146, 0.0154, 0.0163, 0.0172, 0.0180, 0.0187, 0.0192, 0.0196, 0.0200, 0.0203 0.0206, 0.0209, 0.0211, 0.0213, 0.0215, 0.0216, 0.0218, 0.0219, 0.0220, 0.0221, 0.0222, 0.0223 0.0224];
            delay_47b = [0.012429325961106, 0.012637315250533, 0.012885537385767, 0.013151088933065, 0.013439416057938, 0.013755325626353, 0.014103206242086, 0.014486894654777, 0.014909187484472, 0.015370962848411, 0.015869981216818, 0.016399722286832, 0.016948986646910, 0.017503020236639, 0.018046164158904, 0.018564894899205, 0.019049809212022, 0.019495981859572, 0.019902154712264, 0.020269532485280];
            delay_47_5b = [0.012463670421572, 0.012673909676187, 0.012924775180932, 0.013193433047839, 0.013485460868356, 0.013805783213656, 0.014158890380989, 0.014548684761604, 0.014977951658318, 0.015447419496766, 0.015954495699074, 0.016492084092430, 0.017048276704472, 0.017607688486652, 0.018154327450374, 0.018674710961282, 0.019159749575290, 0.019604933597805, 0.020009392078214, 0.020374631744140];
            
            % success rate of transmitted packets per number of nodes
            PSR_ZigBee = [0.52, 0.516, 0.512, 0.508, 0.503, 0.499, 0.494, 0.490, 0.486, 0.483, 0.479, 0.475, 0.471, 0.467, 0.463, 0.458, 0.453, 0.448, 0.442, 0.437, 0.431, 0.425, 0.419, 0.41, 0.407];
            
            PLR = 1-PSR_ZigBee(nodes); %Packet Loss Rate
            
            if packet_size == 31
                TX_delay = delay_31b(nodes);
                delay_signature = Transmission.delay_ECC(1);
            elseif packet_size == 31.5
                TX_delay = delay_31b(nodes);
                delay_signature = Transmission.delay_ECC(1);
            elseif packet_size == 27.5
                TX_delay = delay_27_5b(nodes);
                delay_signature = Transmission.delay_ECC(2);
            else
                TX_delay = delay_31b(nodes);
                delay_signature = Transmission.delay_ECC(1);
            end
            
            retransmissions = 1 + PLR;
            if processing == 1
                delay = ( TX_delay + delay_signature ) * retransmissions;
            else
                delay = TX_delay  * retransmissions;
            end
            
        end
        
        function delay = PLC_delay(packet_size, nodes, processing) %bytes
            
            %e = vpa(exp(1),500);
            %lambda = 0;
            
            %narrowband PLC = long distances, low frequency (100 a 200
            %kHz) and high-voltage transmission
            %link_data_rate = 62500; % 500 kbps ou 62.5 KB/s
            
            % source: "Replicability Analysis of PLC PRIME Networks for Smart Metering Applications" Gonzalez-Sotres L. et al.
            % defined by PRIME
            request_size = 176 /8;
            response_size = 128 /8;
            data_request_size = 132; 
            
            data_rate_DBPSK = 21.4 * 1000 / 8;
            data_rate_D8PSK = 128.6 * 1000 / 8;
            
            avg_csma_priority2 = 17.6 / 1000; %ms level 2 priority (PRIME Specification)
            avg_csma_priority5 = 88.3 / 1000; %ms level 5 priority (PRIME Specification)
            
            control_delay = (request_size + response_size) / data_rate_DBPSK + 2 * avg_csma_priority2;
            
            % 7 bytes MAC header
            %http://www.prime-alliance.org/wp-content/uploads/2014/10/PRIME-Spec_v1.4-20141031.pdf
            packet_size = packet_size + 7;
            
            data_delay = ( data_request_size + packet_size ) / data_rate_D8PSK + 2 * avg_csma_priority5;
            
            PLR_control = 1 + double(Transmission.PLR_PRIME(nodes, 1))/100; % Packet Loss Rate For Control Packets (authentication, errors, etc)
            PLR_data = 1 + double(Transmission.PLR_PRIME(nodes, 2))/100; % Packet Loss Rate For Data Packets
            
            
            if packet_size == 27.5
                delay_signature = Transmission.delay_ECC(2);
            elseif packet_size == 31
                delay_signature = Transmission.delay_ECC(1);
            else
                delay_signature = Transmission.delay_ECC(1);
            end
            
            control_delay = control_delay * PLR_control;
            if processing == 1
                data_delay = ( data_delay + delay_signature ) * PLR_data;
            else
                data_delay = data_delay * PLR_data;
            end
            delay = control_delay + data_delay;
            
        end
        
        
        function PLR = PLR_PRIME(nodes, modulation) %Packet Loss Rate
            
            % source: "Performance assessment of the PRIME MAC layer protocol." Patti G. et al.
            
            %modulations
            % DBPSK_FEC = 1
            % Q8PSK = 2
            
            % DBPSK_FEC_ON for 60-120 nodes
            % if nodes < 60 = almost null (used the value of 60 nodes)
            PLR_DBPSK_60 = 2.82;
            PLR_DBPSK_80 = 8.16;
            PLR_DBPSK_100 = 16.94;
            PLR_DBPSK_120 = 23.52;
            
            % D8PSK_FEC_OFF for 20-120 nodes
            PLR_D8PSK_20 = 5.02;
            PLR_D8PSK_40 = 34.82;
            PLR_D8PSK_60 = 51.14;
            PLR_D8PSK_80 = 60.55;
            PLR_D8PSK_100 = 66.51;
            PLR_D8PSK_120 = 68.76;
            
            % accourding to the graph, the collision are the same, but the max attempts to transmit the packet is different
            % the number of nodes changes the collision rate, the modulation changes the success rate
            
            if nodes > 100 && modulation == 1
                fator = (PLR_DBPSK_120 - PLR_DBPSK_100)/20.0;
                PLR = PLR_DBPSK_100 + fator * double(nodes-100);
            elseif nodes > 80 && modulation == 1
                fator = (PLR_DBPSK_100 - PLR_DBPSK_80)/20.0;
                PLR = PLR_DBPSK_80 + fator * double(nodes-80);
            elseif nodes > 60 && modulation == 1
                fator = (PLR_DBPSK_80 - PLR_DBPSK_60)/20.0;
                PLR = PLR_DBPSK_60 + fator * double(nodes-60);
            elseif nodes > 40 && modulation == 1
                fator = PLR_DBPSK_60/20.0;
                PLR = fator * double(nodes-40);
            elseif nodes <= 40 && modulation == 1
                PLR = 0.0;
                
            elseif nodes > 100 && modulation == 2
                fator = (PLR_D8PSK_120 - PLR_D8PSK_100)/20.0;
                PLR = PLR_D8PSK_100 + fator * double(nodes-100);
            elseif nodes > 80 && modulation == 2
                fator = (PLR_D8PSK_100 - PLR_D8PSK_80)/20.0;
                PLR = PLR_D8PSK_80 + fator * double(nodes-80);
            elseif nodes > 60 && modulation == 2
                fator = (PLR_D8PSK_80 - PLR_D8PSK_60)/20.0;
                PLR = PLR_D8PSK_60 + fator * double(nodes-60);
            elseif nodes > 40 && modulation == 2
                fator = (PLR_D8PSK_60 - PLR_D8PSK_40)/20.0;
                PLR = PLR_D8PSK_40 + fator * double(nodes-40);
            elseif nodes > 20 && modulation == 2
                fator = (PLR_D8PSK_40 - PLR_D8PSK_20)/20.0;
                PLR = PLR_D8PSK_20 + fator * double(nodes-20);
            elseif nodes > 1 && modulation == 2
                fator = PLR_D8PSK_20/20.0;
                PLR = fator * double(nodes);
                
            end
            
        end
        
    end
end