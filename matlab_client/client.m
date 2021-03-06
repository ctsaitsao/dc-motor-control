function data = client(port)
%   provides a menu for accessing PIC32 motor control functions
%
%   client(port)
%
%   Input Arguments:
%       port - the name of the com port.  This should be the same as what
%               you use in screen or putty in quotes ' '
%
%   Example:
%       client('/dev/ttyUSB0') (Linux/Mac)
%       client('COM3') (PC)
%
%   For convenience, you may want to change this so that the port is hardcoded.
   
% Opening COM connection
if ~isempty(instrfind)
    fclose(instrfind);
    delete(instrfind);
end

fprintf('Opening port %s....\n',port);

% settings for opening the serial port. baud rate 230400, hardware flow control
% wait up to 120 secocliennds for data before timing out
mySerial = serial(port, 'BaudRate', 230400, 'FlowControl', 'hardware','Timeout',120); 
% opens serial connection
fopen(mySerial);
% closes serial port when function exits
clean = onCleanup(@()fclose(mySerial));                                 

has_quit = false;
% menu loop
while ~has_quit
    fprintf('PIC32 MOTOR DRIVER INTERFACE\n\n');
    % display the menu options; this list will grow
	fprintf('a: Read current sensor (ADC counts)\nb: Read current sensor (mA)\nc: Read encoder (counts)\nd: Read encoder (deg)\ne: Reset encoder\nf: Set PWM (-100 to 100)\ng: Set current gains\nh: Get current gains\ni: Set position gains\nj: Get position gains\nk: Test current control\nl: Go to angle (deg)\nm: Load step trajectory\nn: Load cubic trajactory\no: Execute trajectory\np: Unpower motor\nq: Quit\nr: Get mode');
    % read the user's choice
    selection = input('\nENTER COMMAND: ', 's');
    % send the command to the PIC32
    fprintf(mySerial,'%c\n',selection);
    % take the appropriate action
    switch selection
        case 'a'
            adc_counts  = fscanf(mySerial,'%d');
            fprintf('The current sensor detects %d ADC counts.\n', adc_counts);
        case 'b'
            mA  = fscanf(mySerial,'%f');
            fprintf('The current sensor detects %f mA.\n', mA); 
        case 'c'
            counts = fscanf(mySerial,'%d');   
            fprintf('The motor angle is %d counts.\n', counts);   
        case 'd'                         
            deg = fscanf(mySerial,'%f');  
            fprintf('The motor angle is %3.2f degrees\n.', deg);   
        case 'e'
            reset_counts = fscanf(mySerial,'%d');
            fprintf('The motor angle has been reset to %d counts.\n',reset_counts);  
        case 'f'
            fprintf('Set duty cycle between -100 and 100:\n');
            duty_cycle = input('\nEnter duty cycle: \n');
            fprintf(mySerial,'%d\n',duty_cycle);
            PR = fscanf(mySerial, '%d');
            fprintf('The PWM PR value is %d.\n',PR);
        case 'g'
            fprintf('Set current gains Kp & Ki:\n');
            Kp_c = input('\nEnter Kp: \n');
            fprintf(mySerial,'%d\n',Kp_c);
            Ki_c = input('\nEnter Ki: \n');
            fprintf(mySerial,'%d\n',Ki_c);
        case 'h'
            current_gains = fscanf(mySerial,'%d %d');
            fprintf('Kp is %d and Ki is %d.\n',current_gains(1),current_gains(2));
        case 'i'
            fprintf('Set position gains Kp, Ki, & Kd:\n');
            Kp_p = input('\nEnter Kp: \n');
            fprintf(mySerial,'%d\n',Kp_p);
            Ki_p = input('\nEnter Ki: \n');
            fprintf(mySerial,'%d\n',Ki_p);
            Kd_p = input('\nEnter Kd: \n');
            fprintf(mySerial,'%d\n',Kd_p);
        case 'j'
            position_gains = fscanf(mySerial,'%d %d');
            fprintf('Kp is %d and Ki is %d Kd is %d.\n',position_gains(1),position_gains(2),position_gains(3));
        case 'k'
            fprintf('ITEST running...\n');
            read_plot_matrix(mySerial);
        case 'l'
            fprintf('Set desired angle in degrees: \n');
            angle = input('\nEnter angle: \n');
            fprintf(mySerial, '%d\n',angle);
            fprintf('Angle set to: %d\n',angle);
            read_plot_matrix(mySerial);
        case 'm'
            fprintf('Set step trajectory: \n');
            reflist = input('\nEnter reflist: \n');
            ref = genRef(reflist,'step');
            [~,len] = size(ref);
            fprintf(mySerial, '%d\n',len);
            for i = 1:len
                fprintf(mySerial, '%d\n',ref(i));
            end
        case 'n'
            fprintf('Set cubic trajectory: \n');
            reflist = input('\nEnter reflist: \n');
            ref = genRef(reflist,'cubic');
            [~,len] = size(ref);
            fprintf(mySerial, '%d\n',len);
            for i = 1:len
                fprintf(mySerial, '%3.2f\n',ref(i));
            end
        case 'o'
            fprintf('Executing trajectory...\n');
            data = read_plot_matrix_deg(mySerial);
        case 'p'
            fprintf('Motor turned off.\n')
        case 'q'
            has_quit = true;             % exit client
        case 'r'
            fprintf('Type 0 for IDLE, 1 for PWM, 2 for ITEST, 3 for HOLD, and 4 for TRACK\n');
            mode = fscanf(mySerial, '%d');
            fprintf('Current mode is: %d\n',mode);
        otherwise
            fprintf('Invalid Selection %c\n', selection);
    end
end

end
