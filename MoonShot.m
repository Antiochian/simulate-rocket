function [] = MoonShot( launch_velocity , launch_angle, args )
%MOONSHOT PLOTTER by HEIRON 2k18 // cDc
%   Synopsis:
%        MoonShow( velocity , launch angle , ...)
%
%   Description:
%        Simuluates a rocket launching with a given speed and velocity in the
%        Earth/Moon system. Defaults to a successful launch if arguements
%        are left blank.
%    
%    Optional Arguments (can be combined and concatenated):
%        -M          start launch on moon instead of planet (light side)
%        -T          execute simulation in Saturn/Titan system instead
%        -L          significantly speeds up animation (can be choppy)
%        -S          force autoscale for square view of system
%        -Z          disable zoomboxes
%        -O          keep viewport zoomed out entirely
%        -G          adds a grid to all views
%        -F          manually specify rocket starting location
%        -P          manually specify starting moon 'phase'

%% - Optional Argument Detection
%set all optional arguments to default to zero
moonlaunch = 0; %done
saturnsystem= 0;  %done, issues
impatient = 0;  %done
squareaxis = 0; %done
zoomout = 0;    %done
removezoom = 0; %done
gridview   = 0; %done
manualsetup = 0; %done
moonphase = 0; %done

if nargin == 1 %throw error if user inputs only 1 value, instead of 0,2 or 3
    error('ERR // Either input no arguments or at least 2.');
    return
    
    elseif nargin == 2
        args='';

    elseif nargin == 3 %if at least one optional arguments are passed
        if strfind(args, 'M')>0 %if option appears in args, enable it
            moonlaunch = 1;
        end
        if strfind(args, 'T')>0
            saturnsystem = 1;
        end
        if strfind(args, 'L')>0
            impatient = 1;
        end
        if strfind(args, 'S')>0
            squareaxis = 1;
        end
        if strfind(args, 'O')>0
            zoomout = 1;
        end
        if strfind(args, 'Z')>0
            removezoom = 1;
        end
        if strfind(args, 'G')>0
            gridview = 1;
        end
        if strfind(args, 'F')>0
            manualsetup = 1;
        end
        if strfind(args, 'P')>0
            moonphase = 1;
        end
else
end
%% - Initial conditions of system (never changed)
G = 9.63E-7;
if saturnsystem ==1
        mM = 1.832198; %NOTE: "mM" is TITAN mass
        mE = 77409.4252;
        radM = 1.482643; %TITAN radius, NOT SATURN
        radE = 33.52254;
        O = 4.568925E-6; %titan angular velocity
        yMoon = 703.39645;%titan of phobos orbit
    else %Earth/Moon values
        mM = 1;
        mE = 83.3;
        radM = 1;
        radE = 3.7;
        O = 2.6615E-6; %Angular velocity of the Moon
        yMoon = 220; %radius of moon orbit
end
%time step
t = 0;
dt = 15;
timelimit=45000; %how many cycles are evaluated
%% - Useful initial conditions for debugging
%set inital position + velocity
if nargin ==0 %default case, for when no arguments are called
        v0 = 0.0066;
        A = 1.96; %note: 1.92 will produce a moonlanding
        args='';
    else
        v0 = launch_velocity;
        A = launch_angle;
end
    
if moonlaunch == 1 
    x = 0;
    y = yMoon - radM;
    A = A + pi; %make rocket launch from underside of Moon)
elseif manualsetup == 1
        goahead = 0;
        while goahead == 0; %cycle will loop until accepted input is given
         prompt= 'Polar co-ordinates (1) or Cartesian (2)?' ;
         coords=input(prompt);
         if coords == 1;
             prompt='Input starting co-ordinates in form [r , theta]: '
                initialpos=input(prompt);
                    x = initialpos(1)*cos(initialpos(2));
                    y = initialpos(1)*sin(initialpos(2));
                goahead = 1;
         elseif coords == 2;
              prompt='Input starting co-ordinates in form (x , y): '
                initialpos=input(prompt);
                x = initialpos(1);
                y = initialpos(2);
                goahead = 1;
         else
             error('ERR // Not understood. Try again?');
         end
     end
    
    else
        x = 0;
        y = radE;
end

if moonphase == 1;
    prompt = 'Enter starting angle of moon from axis (radians): ';
    phase = input(prompt);
else
    phase = pi*0.5; %default phase (moon starts on y-axis)
end
vx = v0*cos(A);
vy = v0*sin(A);
%% - Setup of huge matrices
velRocket=zeros(timelimit,3);  %vector is made huge in advance as frequent concatenation of rows is slow in Matlab
velRocket(1,:) = [vx vy 0];

posRocket=zeros(timelimit,3);  %process is repeated for all changing matrices
posRocket(1,:) = [x y 0];

posMoon=zeros(timelimit,3);
posMoon(1,:) = [0 yMoon 0];

posEarth = [0 0 0]; %Earth is stationary and so only needs 1 row
%% - Motion calculation and function call
for i=1:timelimit
    t=t+dt;
    posMoon(i+1,:) = [yMoon*cos(O*t+phase) yMoon*sin(O*t+phase) t]; %FUNCTION CALL
    AccelR = AccelCalculation(posRocket(i,:),posMoon(i,:), args);

    vx = vx + dt*AccelR(1);
    vy = vy + dt*AccelR(2);
    
    x2 = x+dt*vx;
    y2 = y+dt*vy;
    
    AccelR2 = AccelCalculation([x2 y2],posMoon(i,:), args); %FUNCTION CALL
    vx2 = vx + dt*0.6*(AccelR2(1) + AccelR(1));
    vy2 = vy + dt*0.6*(AccelR2(2) + AccelR(2));
    
    x = x + dt*0.5*(vx+vx2);
    y = y + dt*0.5*(vy+vy2);
    
    posRocket(i+1,:) = [x y t];
    velRocket(i+1,:) = [vx vy t];
    %check to see if simulation should stop or continue
    if norm(posMoon(i,1:2) - [x y]) < radM
        break %stop if rocket hits moon
    elseif norm(posEarth(1:2) - [x y]) < radE
        break %stop if rocket hits earth
    elseif norm(posEarth(1:2) - [x y]) > 600*radE
        break %stop if rocket gets too far away
    else
    end
end
%% - Drawing basic figure
figure('units','normalized','outerposition',[0 0 1 1]); %fit figure to screen
%whitebg([0 .5 .6]); %set background to blue/grey
whitebg('black');


if squareaxis == 1 %optional zoomed-out square feature
    Extremes = [max(posRocket(:,1:2)+10);min(posRocket(:,1:2)-10)]; %find furthest extremity
    MAX = max(max(abs(Extremes))); %find the larger of the max X and Y displacements
    ax1 = axes; %initialise main plot axes
    plot(posRocket(1:(t/dt),1) , posRocket(1:(t/dt),2)); 
    axis manual;
    ax1.XLim = [-MAX MAX]; %set limits to be a square centred on Earth
    ax1.YLim = [-MAX MAX];
    ax1.DataAspectRatio = [1 1 1]; %Keep plot datascale square (otherwise planets look weird)
elseif zoomout == 1 %optional maxzoom feature
    ax1 = axes
    plot(posRocket(1:(t/dt),1) , posRocket(1:(t/dt),2)); 
    axis manual;   
    ax1.XLim = [-(yMoon+radM) (yMoon+radM)]; %set limits to be a square including Moon
    ax1.YLim = [-(yMoon+radM) (yMoon+radM)];
    ax1.DataAspectRatio = [1 1 1];
else %default auto-adjust behaviour
    %find maximum distances from Earth (to draw axes to an appropriate scale)
    Extremes = [max(posRocket(:,1:2)+10);min(posRocket(:,1:2)-10)]; 
    ax1 = axes; %main plot axes
    plot(posRocket(1:(t/dt),1) , posRocket(1:(t/dt),2)); 
    axis manual;
    %Take extremes and manipulate them to fit them into X/YLim's requirements
    ax1.XLim = fliplr(transpose(Extremes(:,1)));
    ax1.YLim = fliplr(transpose(Extremes(:,2)));
    box on;
    ax1.DataAspectRatio = [1 1 1]; %Keep plot datascale square (otherwise planets look weird)    

end
    if gridview == 1 %add grid or remove ticks
            grid(ax1, 'on');
            ax1.XTickLabel = {''};
            ax1.YTickLabel = {''};
    else
            set(ax1,'xtick',[]);
            set(ax1,'ytick',[]);
    end
%draw EARTH
c = posEarth(1,1:2);
pos = [c-radE 2*radE 2*radE];
rectangle('Position',pos,'Curvature',[1 1],'FaceColor','w','EdgeColor','w');
%draw MOON
c = posMoon(1,1:2);
pos = [c-radM 2*radM 2*radM];
%moon needs a handle so it can be deleted later
moondraw=rectangle('Position',pos,'Curvature',[1 1],'FaceColor','w','EdgeColor','w');

%setup path trace of rocket
path = animatedline(posRocket(1,1),posRocket(1,2));
path.Color = 'red';

outline = 0; %boolean operator for later
               
            %set up Rocket Zoom window
            if removezoom == 1
            
            else
                ax3= axes('position',[0.2 .125 .25 .25]);
                ax3.DataAspectRatio = [1 1 1];
                ax3.Title.String = 'Rocket';
                grid(ax3, 'on');                
                box on;
                ax3.XTickLabel = {''};
                ax3.YTickLabel = {''};
               %where outline was
                hold (ax3);
                %setup zoompath (zoomed in rocketpath)
                zoompath = animatedline(ax3,posRocket(1,1),posRocket(1,2));
                zoompath.Color = 'red';
                moondraw3=rectangle(ax3,'Position',pos,'Curvature',[1 1],'FaceColor','w','EdgeColor','w');
                %draw earth (only once 'cause it never moves)
                c = posEarth(1,1:2);
                pos = [c-radE 2*radE 2*radE];
                rectangle('Position',pos,'Curvature',[1 1],'FaceColor','w','EdgeColor','w');
            end
 %% - Animation in figure 
    for k=1:2:(t/dt)
        %k steps in 2 increments and 2 points are drawn at once to speed up the
        %animation, effectively halving the "refresh rate" of the screen
      addpoints(path,posRocket(k,1),posRocket(k,2));
      addpoints(path,posRocket(k+1,1),posRocket(k+1,2));       
      c = posMoon(k,1:2);
      pos = [c-radM 2*radM 2*radM];
      delete(moondraw); %remove , then replace moon image

      %draw in rocketZoom window
              if removezoom == 1
              else %rocketzoom
                addpoints(zoompath,posRocket(k,1),posRocket(k,2));
                addpoints(zoompath,posRocket(k+1,1),posRocket(k+1,2));
                %axes(ax3);
                ax3.XLim = [posRocket(k,1)-10 , posRocket(k,1)+10]; %keep centred on ship
                ax3.YLim = [posRocket(k,2)-10 , posRocket(k,2)+10];
              end
      try
      moondraw=rectangle(ax1,'Position',pos,'Curvature',[1 1],'FaceColor','w','EdgeColor','w');
      catch
      end
          if norm(posMoon(k,1:2) - posRocket(k,1:2)) < 10*radM
              if outline == 0 %First time opening miniview? Set up box
                        if removezoom == 1 %no-zoom option

                          else
                            ax2= axes('position',[0.625 .125 .25 .25]);
                            ax2.DataAspectRatio = [1 1 1];
                            ax2.Title.String = 'Moon';
                            box on;
                            if gridview == 1
                             grid(ax2, 'on');
                             ax2.XTickLabel = {''};
                             ax2.YTickLabel = {''};
                            else
                             set(ax2,'xtick',[]);
                             set(ax2,'ytick',[]);
                            end
                            outline = 1;
                            hold (ax2);
                            %setup moonpath (zoomed in window)
                            moonpath = animatedline(ax2,posRocket(1,1),posRocket(1,2));
                            moonpath.Color = 'red';
                            moondraw2=rectangle(ax2,'Position',pos,'Curvature',[1 1],'FaceColor','w','EdgeColor','w');
                          end
                        else
                  end

            else
          end

        if removezoom == 1 %no-zoom option
               else %draw rocketpath on moonpanel
                   if outline == 0
                   else
                %moonzoom
                addpoints(moonpath,posRocket(k,1),posRocket(k,2));
                addpoints(moonpath,posRocket(k+1,1),posRocket(k+1,2));
                ax2.XLim = [posMoon(k,1)-10*radM , posMoon(k,1)+10*radM]; %keep centred on Moon
                ax2.YLim = [posMoon(k,2)-10*radM , posMoon(k,2)+10*radM];
                %draw moon on 2nd + 3rd axis
                delete(moondraw2);
                moondraw2=rectangle(ax2,'Position',pos,'Curvature',[1 1],'FaceColor','w','EdgeColor','w');
                delete(moondraw3);
                moondraw3=rectangle(ax3,'Position',pos,'Curvature',[1 1],'FaceColor','w','EdgeColor','w');
                   end
        end

        if impatient == 1 
            drawnow limitrate; %update changes
        else
            drawnow;
        end
    end

%% - The End
addpoints(path,posRocket((t/dt),1),posRocket((t/dt),2));
%the twostep method above leaves one point unplotted, this just corrects that
hold off;
end