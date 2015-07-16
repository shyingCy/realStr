function [ position ] = run_ASCTrend( input_args )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
%------����Ϊ�̶������������޸�--------%
% ����
MinPoint = pro_information{3}; %��Ʒ��С�䶯��λ

%����
%K�߱���
Date = data(:,1);
Time = data(:,2);
Open = data(:,3);
High = data(:,4);
Low = data(:,5);
Close = data(:,6);
barLength = size(Date,1); %K������
%
%��������������Ҫ�ı���
entryRecord = []; %���ּ�¼
exitRecord = []; %ƽ�ּ�¼
my_currentcontracts = 0;  %�ֲ�����

% %---------------------------------------%
% %---------------------------------------%
%
% %---------���±���������Ҫ�����޸�--------%
% %���Ա���
value10 = 3 + risk*2;
x1 = 67 + risk;
x2 = 33 - risk;

MyEntryPrice = []; %���ּ۸񣬱����ǿ��־��ۣ�Ҳ�ɸ�����Ҫ����Ϊĳ���볡�ļ۸�

HighestAfterEntry=zeros(barLength,1); %���ֺ���ֵ���߼�
LowestAfterEntry=zeros(barLength,1); %���ֺ���ֵ���ͼ�
AvgEntryPrice = 0;

MarketPosition = 0;
BarsSinceEntry = -1; %�������һ�ο���K������-1��ʾû���֣����ڵ���0��ʾ�ڳֲ������
%
% %����
% for i=value10+1:barLength
%     Range = sum(High(i-10:i-1)-Low(i-10:i-1))/10;
%     j = 1;
%     while j<=10 && TrueCount<1
%         if abs(Open(i-j)-Close(i-j))>= Range*2
%             TrueCount = TrueCount + 1;
%         end
%         j = j+1;
%     end
%     if TrueCount >= 1
%         MRO1 = j;
%     else
%         MRO1 = -1;
%     end
%
%     j = 1;
%     TrueCount = 0;
%     while j<7 && TrueCount<1
%         if(abs(Close(i-j-3)-Close(i-j))>=Range*4.6)
%             TrueCount = TrueCount + 1;
%         end
%         j = j+1;
%     end
%     if(TrueCount>=1)
%         MRO2 = j;
%     else
%         MRO2 = -1;
%     end
%
%     if MRO1>-1
%         value11 = 3;
%     else
%         value11 = value10;
%     end
%     if MRO2>-1
%         value11 = 4;
%     else
%         value11 = value10;
%     end
%
%     iHigh = max(High(i-value11:i-1));
%     iLow = min(Low(i-value11:i-1));
%     WPR = (Close(i-value11)-iHigh)/(iHigh-iLow)*100;
%     value2(i) = 100 - abs(WPR);

for i = 2:barLength
    %-----�����������Ϊ��ֹ������ֹ�����ɾ��------%
    %�漰��ֹ��ı�����HighestAfterEntry��LowestAfterEntry��BarsSinceEntry��MyEntryPrice
    if i > 1
        HighestAfterEntry(i) = HighestAfterEntry(i-1);
        LowestAfterEntry(i) = LowestAfterEntry(i-1);
    end
    if MarketPosition~=0
        BarsSinceEntry = BarsSinceEntry+1;
    end
    
    %-----------------------------------------------%
    %-----------------------------------------------%
    
    if MarketPosition~=1 && value2(i-1)<x2
        [entryRecord,exitRecord,my_currentcontracts,isSucess] = train_buy(entryRecord,exitRecord,my_currentcontracts,...
            Date(i),Time(i),Open(i),1,ConOpenTimes); %����ֻ���޸�max(Open(i),smallswing(i))������Ǽ۸�
        %isSucess�ǿ����Ƿ�ɹ��ı�־
        if isSucess == 1
            BarsSinceEntry = 0;
            MyEntryPrice(1) = Open(i);
            MarketPosition = 1; %��Ҫ�õ�MarketPosition�����ã�����Ҫ��ɾ��
        end
    end
    if MarketPosition~=-1 && value2(i-1)>x1
        [entryRecord,exitRecord,my_currentcontracts,isSucess] = train_sellshort(entryRecord,exitRecord,my_currentcontracts,...
            Date(i),Time(i),Open(i),1,ConOpenTimes);
        if isSucess == 1
            BarsSinceEntry = 0;
            MyEntryPrice(1) = Open(i);
            MarketPosition = -1;
        end
    end
    %---------------ֹ������---------------%
    %=====================================%
    if BarsSinceEntry == 0
        AvgEntryPrice = mean(MyEntryPrice);
        HighestAfterEntry(i) = Close(i);
        LowestAfterEntry(i) = Close(i);
        if MarketPosition ~= 0
            HighestAfterEntry(i) = max(HighestAfterEntry(i),AvgEntryPrice);
            LowestAfterEntry(i) = min(LowestAfterEntry(i),AvgEntryPrice);
        end
    elseif BarsSinceEntry > 0
        HighestAfterEntry(i) = max(HighestAfterEntry(i),High(i));
        LowestAfterEntry(i) = min(LowestAfterEntry(i),Low(i));
    end%���ֵ�����ؽ���
    
    temp=AvgEntryPrice; %���ּ۸����
    if MarketPosition==1 && BarsSinceEntry > 0%���ֺ�bar���
        if HighestAfterEntry(i-1) > (temp+TrailingStart*MinPoint) || abs(HighestAfterEntry(i-1) - (temp+TrailingStart*MinPoint)) < preciseV
            if (Low(i) < (HighestAfterEntry(i-1) - TrailingStop*MinPoint)) || abs(Low(i) - (HighestAfterEntry(i-1) - TrailingStop*MinPoint)) < preciseV
                MyExitPrice = HighestAfterEntry(i-1) - TrailingStop*MinPoint;
                if Open(i) < MyExitPrice
                    MyExitPrice = Open(i);
                end
                %[exitRecord,my_currentcontracts] = train_sell(exitRecord,my_currentcontracts,...
                %    Date(i),Time(i),MyExitPrice,1);
                my_currentcontracts = 0;
                MarketPosition = 0;
                BarsSinceEntry = 0;
                MyEntryPrice = []; %���ÿ��ּ۸�����
            end
        elseif Low(i) < (temp -StopLossSet*MinPoint) || abs(Low(i) - (temp -StopLossSet*MinPoint)) < preciseV
            MyExitPrice = temp - StopLossSet*MinPoint;
            if Open(i) < MyExitPrice
                MyExitPrice=Open(i);
            end
            % [exitRecord,my_currentcontracts] = train_sell(exitRecord,my_currentcontracts,...
            %     Date(i),Time(i),MyExitPrice,1);
            my_currentcontracts = 0;
            MarketPosition = 0;
            BarsSinceEntry = 0;
            MyEntryPrice = []; %���ÿ��ּ۸�����
        end%���ֹ�����
    elseif MarketPosition==-1 && BarsSinceEntry > 0
        if LowestAfterEntry(i-1) < (temp - TrailingStart*MinPoint) || abs(LowestAfterEntry(i-1) - (temp - TrailingStart*MinPoint)) < preciseV
            if (High(i) > (LowestAfterEntry(i-1) + TrailingStop*MinPoint)) || abs(High(i)-(LowestAfterEntry(i-1) + TrailingStop*MinPoint)) < preciseV %������ʾ���ڻ����
                MyExitPrice = LowestAfterEntry(i-1) + TrailingStop*MinPoint;
                if Open(i) > MyExitPrice
                    MyExitPrice = Open(i);
                end
                % [exitRecord,my_currentcontracts] = train_buyToCover(exitRecord,my_currentcontracts,...
                %     Date(i),Time(i),MyExitPrice,1);
                my_currentcontracts = 0;
                MarketPosition = 0;
                BarsSinceEntry = 0;
                MyEntryPrice = []; %���ÿ��ּ۸�����
            end
        elseif High(i) > (temp+StopLossSet*MinPoint) || abs(High(i) - (temp+StopLossSet*MinPoint)) < preciseV
            MyExitPrice = temp+StopLossSet*MinPoint;
            if Open(i) > MyExitPrice
                MyExitPrice=Open(i);
            end
            % [exitRecord,my_currentcontracts] = train_buyToCover(exitRecord,my_currentcontracts,...
            %     Date(i),Time(i),MyExitPrice,1);
            my_currentcontracts = 0;
            MarketPosition = 0;
            BarsSinceEntry = 0;
            MyEntryPrice = []; %���ÿ��ּ۸�����
        end%�ղ�ֹ�����
    end%���ֺ�bar��ؽ���
end

end

