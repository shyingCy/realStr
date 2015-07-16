function [ position ] = run_MESM15( data,instrumentPrefix,M,E,StopLossRate )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%   Attention:�˲�����Ҫdata��������ں�ʱ�����ݣ�instrumentPrefix�Ǻ�Լ������IF���˲�������MinPoint  
%   M,E,StopLossRateΪ���Բ���
lots = 1; %��������

%����
%K�߱���
Date = data(:,1);
Time = data(:,2);
Open = data(:,3);
Close = data(:,6);
barLength = size(Close,1); %K������

%���Ա���
MyEntryPrice = []; %���ּ۸񣬱����ǿ��־��ۣ�Ҳ�ɸ�����Ҫ����Ϊĳ���볡�ļ۸�

MarketPosition = 0;
my_currentcontracts = 0; %�ֲ�����,���Ϊ�棬�ղ�Ϊ��
ConOpenTimes = 0; %�������ִ���

%�ӵڶ������� Ѱ�ҿ��̵�
a=day(Date);
b=diff(a);
index=b>0;
Begin = find(index>0,1)+1;
OpenMoment = Time(Begin);%���̵�
Action = Time(Begin + M);%���翪�ֵ�

for i=1:barLength-1
    %�ٷֱ�ֹ��
    if MarketPosition~=0 %��ʼ����ֹ�� ��MarketPositon=0 ˵���Ѿ����й�ƽ��
        if MarketPosition == 1 %��ǰ����
            LossRate = (EntryPrice - Close(i-1))/EntryPrice;
            % ����ƽ��
            if LossRate > StopLossRate %ֹ�������ֵ
                my_currentcontracts = 0;
                MarketPosition = 0;
                MyEntryPrice = []; %���ÿ��ּ۸�����
            end
        else if MarketPosition == -1 %��ǰ����
                LossRate = (Close(i-1) - EntryPrice)/EntryPrice;
                % ����ƽ��
                if LossRate > StopLossRate %ֹ�������ֵ
                    my_currentcontracts = 0;
                    MarketPosition = 0;
                    MyEntryPrice = []; %���ÿ��ּ۸�����
                end
            end
        end
    end
    %���翪��
    if Time(i) == OpenMoment %��ǿ���ʱ��
        beg  = i ;
    end
    if Time(i) == Action && beg~=0
        for t = 1:i-beg
            winClose = Close(beg:beg-1+t);
            DT = winClose - Close(beg-1+t);%һ�����ڼ�ȥ��ǰ���̼�Close(i-M-1+t)
            %���س�
            if isempty(DT(find(DT>0)))==1
                DDser(t) = 0;
            else
                DDser(t) = max((DT(find(DT>0)))/Close(beg-1+t));
            end
            %�������س�
            if isempty(DT(find(DT<0)))==1
                RDDser(t) = 0;
            else
                RDDser(t) = -min((DT(find(DT<0)))/Close(beg-1+t));
            end
        end
        MDD = sum(DDser)/M;%ƽ�����س�
        MRDD = sum(RDDser)/M;%ƽ���������س�
        Emotion = min(MDD,MRDD);%�г������ȶ���
        if Emotion < E %�г�����ƽ�ȶ�С����ֵ,˵������������������
            EntryPrice = Open(i);
            % ���뿪��
            if Close(i-1) > Close(beg) %tʱ�̹�ָ���ڿ��̼�,����
                if my_currentcontracts < 0 % �ж��Ƿ��Ƿ��֣�������ƽ��
                    my_currentcontracts = 0;
                    MarketPosition = 0;
                end
                
                if abs(my_currentcontracts) <= ConOpenTimes % ���뽨�֣���֤����������������
                    my_currentcontracts = my_currentcontracts + lots;
                    MarketPosition = 1;
                    MyEntryPrice(1) = max(Open(i),highTemp2);
                end
            else % �������֣�tʱ�̹�ָ���ڿ��̼�,����
                if my_currentcontracts > 0 % �ж��Ƿ��Ƿ��֣�������ƽ��
                    my_currentcontracts = 0;
                    MarketPosition = 0;
                end
                
                if abs(my_currentcontracts) <= ConOpenTimes % �������֣���֤����������������
                    my_currentcontracts = my_currentcontracts - lots;
                    MarketPosition = -1;
                    MyEntryPrice(1) = min(Open(i),lowTemp2);
                end
            end
        end
    end
    %��������ʱ����ƽ��
    %��ָƽ��ʱ��Ϊ15:15:00 �ǹ�ָΪ15:00:00
    if  ((((abs(0.6146-Time(i))<0.0001))&&(strcmp(instrumentPrefix,'IF')~=1))||((abs(0.6250-Time(i)))<0.0001))
        if MarketPosition == 1;
            exitPrice = Close(i);
            my_currentcontracts = 0;
            MarketPosition = 0;
            MyEntryPrice = []; %���ÿ��ּ۸�����
        end
        if MarketPosition == -1;
            exitPrice = Close(i);
            my_currentcontracts = 0;
            MarketPosition = 0;
            MyEntryPrice = []; %���ÿ��ּ۸�����
        end
        beg = 0;
    end
end

position = MarketPosition;

end

