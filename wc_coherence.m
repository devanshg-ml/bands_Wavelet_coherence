for file = 1:46
    id = sprintf( '%03d', file );
    disp(id);
    filename_act = strcat('ACT/ACT_',id,'.awd');
    filename_cgm = strcat('CGM/CGM_',id,'.awd');
    id = str2double(id);
    ACT = fopen(filename_act);
    CGM=fopen(filename_cgm);
    if exist(filename_act, 'file')
     if exist(filename_cgm, 'file')   
        tline = fgetl(ACT);
        date = "";
        time = "";
        A = cell(0,1);
        i = 1;
        start = '';
        start = append(start,"WCOH");
        while ischar(tline)
            if i>1 && i<8
               start = append(start,' ', tline);
            end
            if i == 2
                date = tline;
            elseif i == 3
                time = tline;
            elseif i > 7
                A{end+1,1} = str2num(tline);
            end
            tline = fgetl(ACT);
            i = i +1;
        end
        fclose(ACT);
        start = (strsplit(start));


        tlinec = fgetl(CGM);
        C = cell(0,1);
        j = 1;
        while ischar(tlinec)
            if j > 7
                C{end+1,1} = str2num(tlinec);
            end
            tlinec = fgetl(CGM);
            j = j +1;
        end
        fclose(CGM);
        A = cell2mat(A);
        C = cell2mat(C);
        start_dt = strcat(date," ");
        start_dt = strcat(start_dt,time);
        start_dt = datetime(start_dt,'Format','dd-MMM-yy HH:mm');
        timeframe = dateshift(start_dt,'start','minutes',0:5:(length(A)-1)*5);
        bands_time = [15 45; 45 90; 90 180;180 360;360 720;720 1440;1440 2880];
        bands_index = zeros(7,2);
        bands = zeros(7,length(A));
        [wcoh,~,period,coi] = wcoherence(A,C,minutes(5));
        for i = 1:7
            t = 0;
            b_start = bands_time(i,1);
            b_end = bands_time(i,2);
            for c = 1:length(period)
               if round(period(c),'minutes') >= minutes(b_start)
                     if t == 0
                         bands_index(i,1) = c;
                         t=1;
                     end
                end
                if round(period(c),'minutes') > minutes(b_end)
                    break;
                end       
            end
            bands_index(i,2) = c-1;
            bands(i,:) = mean(wcoh(bands_index(i,1):bands_index(i,2),:),1);
        end
        % collpase the bands to average by periods

        sleep_wake = readtable('sleep_time_interval_DG.csv',"VariableNamingRule","preserve",'ReadVariableNames',true);
        band_sleep_time_index = ones(7,2);
        band_wake_time_index = ones(7,2);
        % this loop from 0 to 6 is for 7 days not for 7 bands
        for i = 1:7
            bt = table2array(sleep_wake(id,i+1));
            bt=strrep(string(bt(1)),'00','20');
            bt = datetime(bt,'InputFormat','MM/dd/yy HH:mm','Format','dd-MMM-yyyy HH:mm:ss');
            bt.Minute = 5 * floor(bt.Minute/5);
            wt = table2array(sleep_wake(id,8+i));
            wt=strrep(string(wt(1)),'00','20');
            wt = datetime(wt,'InputFormat','MM/dd/yy HH:mm','Format','dd-MMM-yyyy HH:mm:ss');
            wt.Minute = 5 * floor(wt.Minute/5);
            %disp(timeframe(end));
            if (bt >= start_dt) && (wt >= start_dt) && (bt <= timeframe(end)) && (wt <= timeframe(end))    
                band_sleep_time_index(i,1) = find(timeframe==bt)+1;
               
                band_sleep_time_index(i,2) = find(timeframe==wt);  
                band_wake_time_index(i,1) = band_sleep_time_index(i,2)+1;
                if(i>1)
                    band_wake_time_index(i-1,2) = find(timeframe==bt)+2;
                end
                if(i==7)                   
                    temp = wt + hours(16);
                    if (temp <= timeframe(end))
                        band_wake_time_index(i,2) = find(timeframe==temp);
                    else 
                        band_wake_time_index(i,2) = find(timeframe==timeframe(end));
                    end
                end                
            end
        end
       
        %band_sw_time is the x axis indexes and band_index is the y axis indexes
        %for the bands matrix to selct the sleep and wake time for 7 bands
        
        mean_bands = [];
        sm =[];
        wm =[];
        for i = 1:7 % loopping over 7 bands
            sleep_band = [];
            wake_band = [];
            if ~exist('Bands_data', 'dir')
               mkdir('Bands_data');
            end
            if ~exist(strcat('Bands_data/Participant_',int2str(id)), 'dir')
               mkdir(strcat('Bands_data/Participant_',int2str(id)))
            end
                     if ~exist(strcat('Bands_data/Participant_',int2str(id),'/Sleep'), 'dir')
               mkdir(strcat('Bands_data/Participant_',int2str(id),'/Sleep'))
            end
            if ~exist(strcat('Bands_data/Participant_',int2str(id),'/Wake'), 'dir')
               mkdir(strcat('Bands_data/Participant_',int2str(id),'/Wake'))
            end
            if ~exist(strcat('Bands_data/Participant_',int2str(id),'/One_day'), 'dir')
               mkdir(strcat('Bands_data/Participant_',int2str(id),'/One_day'))
            end
             if ~exist(strcat('Bands_data/One_day'), 'dir')
                mkdir(strcat('Bands_data/One_day'))
             end
            
            for j = 1:7 % looping over 7 days
                one_day_band = [];
                start = string(start(1:9));
                start(2) = strrep(string(start(2)),'00','20');
                start(2) = datetime(start(2),'InputFormat','dd-MMM-yy','Format','dd-MMM-yyyy');
                start(3) = datestr(start(3),'HH:MM');               
                start(3) = datestr(addtodate(datenum(start(3),'HH:MM'),(band_sleep_time_index(j,1) - 1) * (5),'minute'),'HH:MM');
                one_day_band = [start one_day_band];
                if band_sleep_time_index(j,2)~=1
                    sleep_band = [sleep_band bands(i,band_sleep_time_index(j,1):band_sleep_time_index(j,2))];                    
                end
                if band_wake_time_index(j,2)~=1    
                    wake_band = [wake_band bands(i,band_wake_time_index(j,1):band_wake_time_index(j,2))];
                    
                end    
                one_day_band = [one_day_band bands(i,band_sleep_time_index(j,1):band_wake_time_index(j,2))];
                one_day_band = one_day_band.';
                writematrix(one_day_band,strcat('Bands_data/Participant_',int2str(id),'/One_day','/Participant_',int2str(id),'_Band_',int2str(i),'_Day_',int2str(j),'__band.awd.txt'));
                writematrix(one_day_band,strcat('Bands_data/One_day','/Participant_',int2str(id),'_Band_',int2str(i),'_Day_',int2str(j),'__band.awd.txt'));

            end
            sm = [sm mean(sleep_band)];
            wm = [wm mean(wake_band)];
            sleep_band = [start sleep_band];
            wake_band = [start wake_band];
            sleep_band = sleep_band.';
            wake_band = wake_band.';
   
            writematrix(sleep_band,strcat('Bands_data/Participant_',int2str(id),'/Sleep','/Participant_',int2str(id),'_',int2str(i),'_sleep.awd.txt'));
            writematrix(wake_band,strcat('Bands_data/Participant_',int2str(id),'/Wake','/Participant_',int2str(id),'_',int2str(i),'_wake.awd.txt'));
        end
       mean_start = string(strsplit('Band_1 Band_2 Band_3 Band_4 Band_5 Band_6 Band_7'));
       mean_fr = [" " "Sleep" "Wake"];
       mean_bands = [sm.' wm.'];
       mean_bands = [mean_start.' mean_bands];
       mean_bands = [mean_fr;mean_bands];
       writematrix(mean_bands,strcat('Bands_data/Participant_',int2str(id),'/Participant_',int2str(id),'_mean.csv'));
       end
    end
end