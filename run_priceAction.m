function [position] = run_priceAction(data,MinPoint,refn,TrailingStart,TrailingStop,StopLossSet)
%data�ǿ��ߵ��յ���ά���飬minPoint����С�۸�䶯��
%MinPoint = pro_information{3}; %��Ʒ��С�䶯��λ

preciseV = 2e-7; %���ȱ�����������ֵ��ȵľ�������
lots = 1; %����

%K�߱���
Open = data(:,1);
High = data(:,2);
Low = data(:,3);
Close = data(:,4);
barLength = size(Close,1); %K������

%���Ա���
MyEntryPrice = []; %���ּ۸񣬱����ǿ��־��ۣ�Ҳ�ɸ�����Ҫ����Ϊĳ���볡�ļ۸�

HighestAfterEntry=zeros(barLength,1); %���ֺ���ֵ���߼�
LowestAfterEntry=zeros(barLength,1); %���ֺ���ֵ���ͼ�
AvgEntryPrice = 0;

MarketPosition = 0;
my_currentcontracts = 0; %�ֲ�����,���Ϊ�棬�ղ�Ϊ��
ConOpenTimes = 0; %�������ִ���
BarsSinceEntry = -1; %�������һ�ο���K������-1��ʾû���֣����ڵ���0��ʾ�ڳֲ������

startPos = 2*refn+1;
highTemp1 = 0;
highTemp2 = 0;
lowTemp1 = 0;
lowTemp2 = 0;

for i=startPos:barLength
    
    HighestAfterEntry(i) = HighestAfterEntry(i-1);
    LowestAfterEntry(i) = LowestAfterEntry(i-1);
    if MarketPosition~=0
        BarsSinceEntry = BarsSinceEntry+1;
    end
    
    if High(i-refn)>High(i-1) && High(i-refn)>High(i-2*refn+1)
        highTemp1 = highTemp2;
        highTemp2 = High(i-refn);
    end
    
    if Low(i-refn)<Low(i-1) && Low(i-refn)<Low(i-2*refn+1)
        lowTemp1 = lowTemp2;
        lowTemp2 = Low(i-refn);
    end
    
    if highTemp2 > highTemp1 && lowTemp2 > lowTemp1
        if High(i) > highTemp2
            if my_currentcontracts < 0 % �ж��Ƿ��Ƿ��֣�������ƽ��
                my_currentcontracts = 0;
                MarketPosition = 0;
                BarsSinceEntry = 0;
            end
            
            if abs(my_currentcontracts) <= ConOpenTimes % ���뽨�֣���֤����������������
                my_currentcontracts = my_currentcontracts + lots;
                MarketPosition = 1;
                BarsSinceEntry = 0;
                MyEntryPrice(1) = max(Open(i),highTemp2);
            end
        end
    end
    if highTemp2 < highTemp1 && lowTemp2 < lowTemp1
        if Low(i) < lowTemp2
            if my_currentcontracts > 0 % �ж��Ƿ��Ƿ��֣�������ƽ��
                my_currentcontracts = 0;
                MarketPosition = 0;
                BarsSinceEntry = 0;
            end
            
            if abs(my_currentcontracts) <= ConOpenTimes % �������֣���֤����������������
                my_currentcontracts = my_currentcontracts - lots;
                MarketPosition = -1;
                BarsSinceEntry = 0;
                MyEntryPrice(1) = min(Open(i),lowTemp2);
            end
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

position = MarketPosition;

end

