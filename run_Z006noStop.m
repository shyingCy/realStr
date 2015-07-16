function [ position ] = run_Z006noStop( barData,MinPoint,realBegDate,Length,Period )
% Attention:barDataΪƷ��2010-04-16�����ڵ���ά���ݡ�
% MinPoint��Ʒ����С�䶯��λ
% realBegDate��ʵ�̿�ʼ���ڣ���ʽ��'2010-04-16'
% Length,PeriodΪ���Բ���

Date = barData(:,1);
Time = barData(:,2);
Open = barData(:,3);
High = barData(:,4);
Low = barData(:,5);
Close = barData(:,6);

%% �����������

richtung=0;

barLength = size(Close,1);

backBar = 2; %SwingHighPrice = SwingHigh( 1, Close, 1,2);������ʽ�е����һ������
backTraceBar = 1; %��ǰ����backTraceBar��K
ZZ=zeros(barLength,1);
ZZ(1:backBar+backTraceBar+1,1) = repmat(price(1),backBar+backTraceBar+1,1);
if backBar==2
    if price(1) > price(2)
        SwingHighPrice = price(1);
        SwingLowPrice = 0;
    else
        SwingLowPrice = price(1);
        SwingHighPrice = 0;
    end
end
for i=backBar+backTraceBar+1:barLength
    %ԭ�汾��ֱ���ü۸������TB���SwingHighprice
    %������2��k����������һ��K�ĵ�һ��swinghighprice����swinglowprice
    %Ҳ����TB�����SwingHighPrice = SwingHigh( 1, Close, 1,2);������ʽ
    if price(i-1-backTraceBar) > price(i-backTraceBar) && price(i-1-backTraceBar) >= price(i-backBar-backTraceBar)
        SwingHighPrice = price(i-1-backTraceBar);
    elseif price(i-1-backTraceBar) < price(i-backTraceBar) && price(i-1-backTraceBar) <= price(i-backBar-backTraceBar)
        SwingLowPrice = price(i-1-backTraceBar);
    end
     
    ZZ(i,1) = ZZ(i-1,1);
    
    if SwingHighPrice~=0
        relKurs  = (SwingHighPrice-ZZ(i,1))/ZZ(i,1)*100;
        
        if (richtung<=0)&&(relKurs>=prozent)
            ZZ(i,1) = SwingHighPrice;
            richtung=1;
        elseif (richtung==1)&&(SwingHighPrice >= ZZ(i,1))
            ZZ(i,1) = SwingHighPrice;
        end
    elseif SwingLowPrice~=0
        relKurs  = (SwingLowPrice-ZZ(i,1))/ZZ(i,1)*100;
        
        if (richtung>=0)&&(-relKurs>=prozent)
            ZZ(i,1) = SwingLowPrice;
            richtung=-1;
        elseif (richtung==-1)&&(SwingLowPrice <= ZZ(i,1))
            ZZ(i,1) = SwingLowPrice;
        end
    end
    SwingHighPrice = 0;
    SwingLowPrice = 0;
end



end

