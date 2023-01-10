function f = MauiDiameterDataCleaning

source_path = '';                                   %Source path of your dataset
filePattern = fullfile(source_path, '**/*.csv');    %Set the arrangement of the file pattern, default is to subfolders containg .csv's
numSections = 1;                                    %Determines the number of sections to split the data up into, default is 1
offset = 5;                                         %Sets the window around any flagged outliers equal to median with window size equal to offset

global OutputFiles;
OutputFiles = {};



Files = dir(filePattern);

fig = uifigure;
fig.Position = [209 178 2224 1152];
ax1 = uiaxes('Parent',fig,...
            'Units','pixels',...
            'Position', [100, 100, 1000, 1000]);
ax2 = uiaxes('Parent',fig,...
            'Units','pixels',...
            'Position', [1200, 100, 800, 1000]);

ax1.Title.String = 'Original Maui Data';
ax1.YLabel.String = 'Diameter (mm)';
ax1.XLabel.String = 'Time (seconds)';

ax2.Title.String = 'Filtered Maui Data';
ax2.YLabel.String = 'Diameter (mm)';
ax2.XLabel.String = 'Time (seconds)';

lbl = uilabel(fig);
lbl.Position = [1000, 1070, 400, 100];
lbl.WordWrap = "on";

for k = 1 : length(Files)
       
        baseFileName = Files(k).name;
        fullFileName = fullfile(Files(k).folder, baseFileName);
        lbl.Text = baseFileName;

        %Split data based by Artery

        if contains(Files(k).name, 'ICA')
            T = readtable(fullFileName);
            artery = 'ICA';
        elseif contains(Files(k).name, 'VA')
            T = readtable(fullFileName);
            artery = 'VA';
        elseif contains(Files(k).name, 'CCA')
            T = readtable(fullFileName);
            artery = 'CCA';
        end

        %Extract time and convert all data into mm 

        time = table2array(T(:, 'time_seconds_'));

        try 
            diameter = table2array(T(:, 'media_mediaDistance_mm_'));
        catch ME
            diameter = table2array(T(:, 'media_mediaDistance_cm_')) * 10;
        end
        
        plot(ax1, time, diameter)
        hold(ax1, 'on')
        
        %% Process two hampel filters to detect outliers.
        
        [diameter, j, xmedian, ~] = hampel(diameter, 200);
        diameter = smoothOutliers(diameter, j, xmedian, offset, median(diameter));

        [diameter, j, xmedian, ~] = hampel(diameter, 50);
        diameter = smoothOutliers(diameter, j, xmedian, offset, median(diameter));

        [ipt, ~] = findchangepts(diameter,'MaxNumChanges',numSections,'Statistic','mean'); 
        ipt = transpose(ipt);
        ipt = [1, ipt, length(diameter)]; 

        diameter_clean = diameter;

        for i = 2 : length(ipt)
                section_variance = var(diameter_clean(ipt(i-1):ipt(i)));
                section_mean = mean(diameter_clean(ipt(i-1):ipt(i)));
             
                %%If the data is out of the realm of physiological significance, or the variance is too high then zero out this section. 
                %%Different arteries will require different values.
             
             if (strcmp(artery, 'VA'))
                    if (section_mean > 5 || section_mean < 1.5 || section_variance > 0.25 || ipt(i)-ipt(i-1) < 1000)   
                        diameter_clean(ipt(i-1):ipt(i)) = 0;
                    else
                        diameter_clean(ipt(i-1):ipt(i)) = hampel(diameter_clean(ipt(i-1):ipt(i)), 200);
                        diameter_clean(ipt(i-1):ipt(i)) = hampel(diameter_clean(ipt(i-1):ipt(i)), 50);
                    end

             elseif (strcmp(artery, 'ICA'))
                     if (section_mean > 7 || section_mean < 3 || section_variance > 0.25 || ipt(i)-ipt(i-1) < 1000)   
                        diameter_clean(ipt(i-1):ipt(i)) = 0;
                     else
                        diameter_clean(ipt(i-1):ipt(i)) = hampel(diameter_clean(ipt(i-1):ipt(i)), 200);
                        diameter_clean(ipt(i-1):ipt(i)) = hampel(diameter_clean(ipt(i-1):ipt(i)), 50);
                     end
                     
               %%Add more elseif statements to include viable physiological metrics for other arteries
              
             end

        end

        
        plot(ax1, time, diameter_clean)
        hold(ax1, 'off')

        diameter_sections = find(diameter_clean ~= 0);
        plot(ax2, time(diameter_sections), diameter_clean(diameter_sections))

        btn = uibutton(fig,'push',...
                   'Position',[2100, 100, 100, 22],...
                   'Text', 'Done',...
                   'ButtonPushedFcn', @(btn,event) saveButtonPushed(k, fig, baseFileName, Files, time, diameter, diameter_clean, diameter_sections));
        uiwait(fig);
 
end

function saveButtonPushed(k, fig, baseFileName, Files, time, diameter, diameter_clean, diameter_sections)
    answer = questdlg(strcat('Would you like to save subject   ', baseFileName),'Save Prompt','Yes','No','No');
    
    switch answer
        case 'Yes'
            baseFileName = strcat(baseFileName(1:length(baseFileName)-4), '_Clean.mat');
            FileName = fullfile(Files(k).folder, baseFileName);
            
            OutputFiles = [OutputFiles baseFileName];
            
            save(FileName, 'time', 'diameter', 'diameter_sections', 'diameter_clean');
            
        case 'No'
            
    end
    
    uiresume(fig);
end

function diameterCleaned = smoothOutliers(diameter_clean, j, xmedian, offset, median)
    
    for m = 1:length(j)
        if (j(m) == 1)
            loc = m;
            if (loc <= offset)
                diameter_clean(1:loc+offset) = xmedian(loc);
            elseif (loc+offset >= length(diameter_clean))
                diameter_clean(loc:length(diameter_clean)) = median;
            else 
                diameter_clean(loc-offset:loc+offset) = median;
            end
        end
    end
    
    diameterCleaned = diameter_clean;

end

f = OutputFiles;
end




