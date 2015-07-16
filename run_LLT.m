function [ position ] = run_LLT( barData,realBegDate,Length,q )
% Attention:barDataΪƷ��2010-04-16�����ڵ���ά���ݡ�
% realBegDate��ʵ�̿�ʼ���ڣ���ʽ��'2010-04-16'
% Length,q Ϊ���Բ���

%����
%K�߱���
Date = barData(:,1);
Close = barData(:,6);
barLength = size(Date,1); %K������

% ���ױ���
my_currentcontracts = 0;  %�ֲ�����
MarketPosition = 0;
ConOpenTimes = 0;
lots = 1;

%% ���㽻������
%���Ա���
a=2/(Length+1);% ��ֵ
LLTvalue = zeros(barLength,1);
for t=1:2
    LLTvalue(t) = Close(t);
end
for t = 3:barLength   %����LLT������
    LLTvalue(t)=(a-0.25*a^2)*Close(t)+0.5*a^2*Close(t-1)-(a-0.75*a^2)*Close(t-2)+(2-2*a)*LLTvalue(t-1)-(1-a)^2*LLTvalue(t-2);
end
D = zeros(barLength,1);
D(2:end)=diff(LLTvalue); %����

%% ʵ�̽���
% �ҳ�ʵ��������ʼ�±�
realBegDate = datenum(realBegDate);
realBegIndex = find(Date>=realBegDate,1);
if isempty(realBegIndex)
    error('realBegDate is not right!');
end

realData = barData(realBegIndex:end,:);
d = D(realBegIndex:end);
barLength = size(realData,1);

for i=3:barLength
    % ���뽨��
    if MarketPosition~=1 && d(i-2)>q
        if my_currentcontracts < 0 % �ж��Ƿ��Ƿ��֣�������ƽ��
            my_currentcontracts = 0;
            MarketPosition = 0;
        end
        
        if abs(my_currentcontracts) <= ConOpenTimes % ���뽨�֣���֤����������������
            my_currentcontracts = my_currentcontracts + lots;
            MarketPosition = 1;
        end
    end
    % ��������
    if MarketPosition~=-1 && d(i-2)<q
        if my_currentcontracts > 0 % �ж��Ƿ��Ƿ��֣�������ƽ��
            my_currentcontracts = 0;
            MarketPosition = 0;
        end
        
        if abs(my_currentcontracts) <= ConOpenTimes % �������֣���֤����������������
            my_currentcontracts = my_currentcontracts - lots;
            MarketPosition = -1;
        end
    end
     
end

position = MarketPosition;

end

