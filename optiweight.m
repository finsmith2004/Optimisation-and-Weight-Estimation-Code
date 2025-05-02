%% Clear Workspace and Setup
clear all;
clc;

%% Design Variables (Inputs) with as many values each
b_values            = [1.1];
c_r_values          = [0.3];        
b_trans_values      = [0.35];       
LE_sweep_deg_values = [40];          
taper_ratio_values  = [0.45];       
c_nose_values       = [0.5];       
%% Tail values have minimal effect on speed
h_tail_values       = [0.1];        
c_r_tail_values     = [0.208];     
c_t_tail_values     = [0.12];     
tail_sweep_deg_values = [25]; 

%% Input Parameters for Spar Counts
num_longitudinal_spars_wing = 3;   
num_longitudinal_spars_body = 4;   
num_spanwise_spars_wing   = 0;   
num_spanwise_spars_body   = 5;   

%% Input Parameters for Inlet Spars 
n_inlet_spars = 2;      % Number of inlet spars
h_inlet_spars = 0.02;   % Height of each inlet spar [m]
t_inlet_spars = 0.035;  % Thickness of each inlet spar [m]
phi = 0.7;              % Fill ratio (dimensionless)
phi_body = 0.7;
phi_inlet = 0.7;
Tail_dihedral = deg2rad(60);

%% Constants (Aerofoil)
tc_wing  = 0.101;
xc_wing  = 0.269;
tc_nose  = 0.15;
xc_nose  = 0.45;
tc_tail  = 0.12;
xc_tail  = 0.30;

W_TOTAL    = 245;           % Total Weight [N]
rho_cruise = 1.225;         % Density [kg/m³]
V_cruise   = 100;           % Cruise Speed [m/s]
mu         = 1.7894e-5;     % Dynamic viscosity [kg/m·s]
M          = 160/330;          % Mach number (max speed estimation)

Qc         = 1.0;  
Qc_tail    = 1.03;
Cd0_misc   = 0.03;

T_available = 480;         % Available thrust [N]
e = 0.88;                   % Oswald efficiency factor
e_body = 0.8;
a0_wing            = 2*pi;   
a0_body            = 2*pi*1/1.1;   
a0_tail_horizontal = 2*pi;   

alpha_i_tail = 2;  

eta_body = 1.0;      
eta_h    = 0.95;     
dEdAlpha = 0.1;      
 
alpha0_wing    =  0;    % Zero‑lift AoA for wing [deg]
alpha0_body    =  -2;    % Zero‑lift AoA for body [deg]
alpha0_tail    =  0;    % Zero‑lift AoA for tail [deg]
twist_wing     =  -0.6;  % Mean geometric wing twist [deg]
twist_body = 2;
dE_upwash      =   0.95; % dε_upwash/dα (body)  
 

%% Weight Estimation Constants
t_foam = 0.005;
w_skin_fibreglass    = 1.53;% [N/m²]
w_skin_foam = 931.95*t_foam;
w_skin = w_skin_foam + w_skin_fibreglass;
w_paint   = 2.941995;   % [N/m²]  
n_engines       = 2;
W_engine        = 1.990 * 9.81;     
h_inlet         = 0.18;   
l_inlet         = 0.3;    
w_inlet         = 13000;    % [N/m²]
depth_inlet = 0.02;
% Spar weight parameters
w_spanwise_spar     = 13000;   % [N/m²]
w_longitudinal_spar = 13000;   % [N/m²]
t_long = 0.045;
% Constants for leading‐edge spars
r_LE_spar = 0.03;     % radius of each LE spar [m]
w_LE_spar = 13000;     % unit weight for LE spar material [N/m³]
% Trailing-Edge Spar constants
r_TE_spar   = 0.02;    % radius of each TE spar [m]
w_TE_spar   = 13000;    % material weight per unit volume [N/m^3]
r_spanwise_spar = 0.03;  % Spar radius in meters

%% Read Aerofoil Data from Excel
dataTable = readtable('Interpolation.xlsx', 'ReadVariableNames', false);
dataTable.Properties.VariableNames = {'1', '2', 'col3', 'xwing', 'ywing','3','xbody','ybody'};
rows = 1:5000;
body_x = dataTable.xbody(rows);
body_y = dataTable.ybody(rows);
wing_x = dataTable.xwing(rows);
wing_y = dataTable.ywing(rows);

disp('Size of wing aerofoil coordinate arrays:');
disp([length(wing_x), length(wing_y)]);
disp('Size of body aerofoil coordinate arrays:');
disp([length(body_x), length(body_y)]);

%% Aerofoil Interpolation for Wing Aerofoil
nWing = length(wing_x);
midIdxWing = floor(nWing/2);
wing_upper_x = wing_x(1:midIdxWing);
wing_upper_y = wing_y(1:midIdxWing);
wing_lower_x = wing_x(midIdxWing+1:end);
wing_lower_y = wing_y(midIdxWing+1:end);
wing_lower_x = flipud(wing_lower_x);
wing_lower_y = flipud(wing_lower_y);

wingSplineUpper = spline(wing_upper_x, wing_upper_y);
wingSplineLower = spline(wing_lower_x, wing_lower_y);

min_x_wing = min(wing_x);
max_x_wing = max(wing_x);

x_fine_wing_plot = linspace(min_x_wing, max_x_wing, 1000);
y_wing_upper_fine = ppval(wingSplineUpper, x_fine_wing_plot);
y_wing_lower_fine = ppval(wingSplineLower, x_fine_wing_plot);
figure;
plot(x_fine_wing_plot, y_wing_upper_fine, 'r-', 'LineWidth', 2); hold on;
plot(x_fine_wing_plot, y_wing_lower_fine, 'b-', 'LineWidth', 2);
scatter(wing_x, wing_y, 30, 'k', 'x', 'LineWidth', 0.7);
xlabel('Chordwise Location, x [m]');
ylabel('y [m]');
title('Wing Aerofoil: Spline Interpolation');
legend('Upper Surface', 'Lower Surface', 'Data Points');
grid on;
hold off;

%% Aerofoil Interpolation for Body Aerofoil
nBody = length(body_x);
midIdxBody = floor(nBody/2);
body_upper_x = body_x(1:midIdxBody);
body_upper_y = body_y(1:midIdxBody);
body_lower_x = body_x(midIdxBody+1:end);
body_lower_y = body_y(midIdxBody+1:end);
body_lower_x = flipud(body_lower_x);
body_lower_y = flipud(body_lower_y);

bodySplineUpper = spline(body_upper_x, body_upper_y);
bodySplineLower = spline(body_lower_x, body_lower_y);

min_x_body = min(body_x);
max_x_body = max(body_x);

x_fine_body_plot = linspace(min_x_body, max_x_body, 1000);
y_body_upper_fine = ppval(bodySplineUpper, x_fine_body_plot);
y_body_lower_fine = ppval(bodySplineLower, x_fine_body_plot);
figure;
plot(x_fine_body_plot, y_body_upper_fine, 'r-', 'LineWidth', 2); hold on;
plot(x_fine_body_plot, y_body_lower_fine, 'b-', 'LineWidth', 2);
scatter(body_x, body_y, 30, 'k', 'x', 'LineWidth', 0.7);
xlabel('Chordwise Location, x [m]');
ylabel('y [m]');
title('Body Aerofoil: Spline Interpolation');
legend('Upper Surface', 'Lower Surface', 'Data Points');
grid on;
hold off;

%% Spline Utility Definitions
clamp = @(val, vmin, vmax) max(min(val, vmax), vmin);
localThicknessAtX_Wing = @(x, chord) ( ppval(wingSplineUpper, clamp(x/chord, min_x_wing, max_x_wing)) - ppval(wingSplineLower, clamp(x/chord, min_x_wing, max_x_wing)) ) * chord;
localThicknessAtX_Body = @(x, chord) ( ppval(bodySplineUpper, clamp(x/chord, min_x_body, max_x_body)) - ppval(bodySplineLower, clamp(x/chord, min_x_body, max_x_body)) ) * chord;

%% Precompute Normalized Aerofoil Areas (Unit Chord)
x_norm_wing = linspace(0, 1, 100);
wing_upper_norm = ppval(wingSplineUpper, x_norm_wing);
wing_lower_norm = ppval(wingSplineLower, x_norm_wing);
normalized_area_wing = trapz(x_norm_wing, wing_upper_norm - wing_lower_norm);
x_norm_body = linspace(0, 1, 100);
body_upper_norm = ppval(bodySplineUpper, x_norm_body);
body_lower_norm = ppval(bodySplineLower, x_norm_body);
normalized_area_body = trapz(x_norm_body, body_upper_norm - body_lower_norm);

%% Optimization Design Loop Preallocation
MaxDesigns = numel(b_values) * numel(c_r_values) * numel(b_trans_values) * ...
             numel(LE_sweep_deg_values) * numel(taper_ratio_values) * ...
             numel(c_nose_values) * numel(h_tail_values) * numel(c_r_tail_values) * numel(c_t_tail_values) * numel(tail_sweep_deg_values);
Designs = repmat(struct(), MaxDesigns, 1);
DesignCount = 0;

%% Nested Loops Over Design Variables
for i = 1:length(b_values)
    b = b_values(i);
    for j = 1:length(c_r_values)
        c_r = c_r_values(j);
        for k = 1:length(b_trans_values)
            b_trans = b_trans_values(k);
            for m = 1:length(LE_sweep_deg_values)
                LE_sweep_deg = LE_sweep_deg_values(m);
                LE_sweep_rad = deg2rad(LE_sweep_deg);
                for n = 1:length(taper_ratio_values)
                    taper_ratio = taper_ratio_values(n);
                    for nn = 1:length(c_nose_values)
                        c_nose = c_nose_values(nn);
                        
                        % Calculate LE_lambda_body from c_nose and b_trans
                        LE_lambda_body = atan(2 * (c_nose+c_r) / b_trans);
                        LE_lambda_body_Quarter = atan(0.75*2 * (c_nose+c_r) / b_trans);
                        
                        
                        %% Wing Geometry
                        c_t = taper_ratio * c_r;
                        half_span = b / 2;
                        x_LE_tip = half_span * tan(LE_sweep_rad);
                        S_wing = ((b - b_trans) * (c_r + c_t)) / 2;
                        AR_wing = (b - b_trans)^2 / S_wing;
                        lambda_wing = c_t / c_r;
                        MAC_wing = (2/3) * c_r * ((1 + lambda_wing + lambda_wing^2) / (1 + lambda_wing));
                        tan_Lambda_c4 = tan(LE_sweep_rad) - (1 - taper_ratio) / (AR_wing * (1 + taper_ratio));
                        LE_lamdba_wing_quarter = atan(tan_Lambda_c4); % In radians
                        %% Body Geometry
                        c_r_nose = c_r;
                        MAC_body = c_r+c_nose/2;
                        
                        b_tri = b_trans;
                        x_LE_tip_body = (b_tri / 2) * tan(LE_sweep_rad);
                        S_tri = 0.5 * b_tri * c_nose;
                        S_rect = b_trans * c_r_nose;
                        S_body = (S_tri + S_rect) * 0.9;
                        AR_body = (b-b_trans)^2 / S_body;
                        
                        Re_wing = (rho_cruise * V_cruise * MAC_wing) / mu;
                        Re_body = (rho_cruise * V_cruise * MAC_body) / mu;
                        
                        %% Loop Over Tail Variables
                        for p = 1:length(h_tail_values)
                            h_tail = h_tail_values(p);
                            for q = 1:length(c_r_tail_values)
                                c_r_tail = c_r_tail_values(q);
                                for r = 1:length(c_t_tail_values)
                                    c_t_tail = c_t_tail_values(r);
                                    for s = 1:length(tail_sweep_deg_values)
                                        tail_sweep_deg = tail_sweep_deg_values(s);
                                        tail_sweep_rad = deg2rad(tail_sweep_deg);
                                        
                                        %% Tail Geometry
                                        % Tail geometry definitions
                                        S_tail = h_tail * ((c_r_tail + c_t_tail) / 2);
                                        lambda_tail = c_t_tail / c_r_tail;
                                        AR_tail_horizontal = ((2 * h_tail * cos(deg2rad(90 - alpha_i_tail)))^2) / (S_tail * cos(deg2rad(90 - alpha_i_tail)));
                                        taper_ratio_tail = c_t_tail/c_r_tail;
                                        AR_tail = S_tail/h_tail^2;
                                        LE_lamdba_tail = atan(h_tail/c_r_tail);
                                        S_horizontal = S_tail * cos(LE_lamdba_tail);
                                        % Compute MAC_tail and Re_tail if needed
                                        MAC_tail = (2/3) * c_r_tail * ((1 + lambda_tail + lambda_tail^2) / (1 + lambda_tail));
                                        Re_tail = (rho_cruise * V_cruise * MAC_tail) / mu;
                                        l_h = 0.6/h_tail;
                                        h_h = 0.1/h_tail;
                                        %% Tail Aerodynamic Calculations
                                        % Using tail sweep instead of LE_sweep in the tail section:
                                        term_tail_sweep = (a0_tail_horizontal * cos(tail_sweep_rad)) / (pi * AR_tail_horizontal);
                                        CLa_tail_horizontal_tail = (a0_tail_horizontal * cos(tail_sweep_rad)) / (sqrt(1 + term_tail_sweep^2) + term_tail_sweep);
                                        
                                       
                                        

                                        %% Aerodynamic Calculations for entire configuration
                                        % 1) Reference area
                                        S_ref = S_wing + S_body + S_horizontal;
                                        
                                        % 2) Individual lift‑curve slopes (linear lifting‑line)
                                        term_wing = (a0_wing * cos(LE_sweep_rad)) / (pi * AR_wing);
                                        CLa_wing  = (a0_wing * cos(LE_sweep_rad)) / (sqrt(1 + term_wing^2) + term_wing);
                                        
                                        term_body = (a0_body * cos(LE_sweep_rad)) / (pi * AR_body);
                                        CLa_body  = (a0_body * cos(LE_sweep_rad)) / (sqrt(1 + term_body^2) + term_body);
                                        
                                        term_tail = (a0_tail_horizontal * cos(tail_sweep_rad)) / (pi * AR_tail_horizontal);
                                        CLa_tail  = (a0_tail_horizontal * cos(tail_sweep_rad)) / (sqrt(1 + term_tail^2) + term_tail);

                                        
                                        %% Wetted Areas and Friction Calculations
                                        S_wet_wing = 2.3 * S_wing;
                                        S_wet_body = 2.3 * S_body;
                                        S_wet_tail = 2.0 * S_tail;
                                        
                                        Cf_lam_wing = 1.328 / sqrt(Re_wing);
                                        Cf_turb_wing = 0.455 / ((log10(Re_wing))^2.58 * (1 + 0.144 * M^2)^0.65);
                                        Cf_wing = 0.4 * Cf_lam_wing + 0.6 * Cf_turb_wing;
                                        
                                        Cf_lam_body = 1.328 / sqrt(Re_body);
                                        Cf_turb_body = 0.455 / ((log10(Re_body))^2.58 * (1 + 0.144 * M^2)^0.65);
                                        Cf_body = 0.3 * Cf_lam_body + 0.7 * Cf_turb_body;
                                        
                                        Cf_lam_tail = 1.328 / sqrt(Re_tail);
                                        Cf_turb_tail = 0.455 / ((log10(Re_tail))^2.58 * (1 + 0.144 * M^2)^0.65);
                                        Cf_tail = 0.25 * Cf_lam_tail + 0.75 * Cf_turb_tail;
                                        
                                        FF_wing = 2 * (1 + (0.6 / xc_wing) * tc_wing + 100 * tc_wing^4) * (1.34 * M^0.18 * cos(LE_lamdba_wing_quarter)^0.28);
                                        FF_body = 2 * (1 + (0.6 / xc_nose) * tc_nose + 100 * tc_nose^4) * (1.34 * M^0.18 * cos(LE_lambda_body_Quarter)^0.28);
                                        FF_tail = 1.1 * 2 * (1 + (0.6 / xc_tail) * tc_tail + 100 * tc_tail^4) * (1.34 * M^0.18 * cos(LE_lamdba_tail)^0.28);
                                        
                                        CD0_wing = (Cf_wing * FF_wing * Qc * S_wet_wing) / S_wing;
                                        CD0_body = (Cf_body * FF_body * Qc * S_wet_body) / S_body;
                                        CD0_tail = (Cf_tail * FF_tail * Qc_tail * S_wet_tail) / S_tail;
                                        
                                        CD0_total = CD0_wing + CD0_body + CD0_tail + Cd0_misc;
                                        CL_cruise = (2 * W_TOTAL) / (rho_cruise * V_cruise^2 * S_ref);
                                        k_total = ((1 / (pi * e * AR_wing)) + (1.1 / (pi * e_body * AR_body))) / 2;
                                        CD_total = CD0_total + k_total * CL_cruise^2;
                                        
                                        %% Thrust Balance to Find V_max
                                        thrust_eq = @(V) 0.5 * rho_cruise * V.^2 * S_ref * (CD0_total + k_total * ((2 * W_TOTAL) / (rho_cruise * V.^2 * S_ref)).^2) - T_available;
                                        V_guess = V_cruise * 1.5;  
                                        options = optimoptions('fsolve', 'Display', 'off');
                                        [V_max_sol, ~, exitflag] = fsolve(thrust_eq, V_guess, options);
                                        
                                        if (exitflag > 0) && (V_max_sol > 0)
                                            V_max = V_max_sol;
                                            T_W_max = T_available / W_TOTAL;
                                            dynamic_pressure = 0.5 * rho_cruise * V_max^2;
                                            WS_local = W_TOTAL / S_ref;
                                            term_inside = T_W_max - dynamic_pressure * (CD0_total / WS_local);
                                            if term_inside > 0
                                       
                                                n_max = sqrt( (dynamic_pressure / (k_total * WS_local)) * term_inside);
                                            else
                                                n_max = NaN;
                                            end
                                            
                                            % 3) Correct for upwash/downwash & efficiencies
                                          Mv       = V_max / 340;
                                          beta     = sqrt(1 - Mv^2);
                                          CLa_w_M  = CLa_wing / beta;
                    
                                          KA       = 1/AR_wing - 1/(1+AR_wing^1.7);
                                          Kl       = (10 - 3*taper_ratio)/7;
                                          Kh       = (1 - abs(h_h)) / ((2*l_h)^(1/3));
                    
                                          dE_down  = 4.44 * (KA*Kl*Kh*sqrt(cos(LE_lamdba_wing_quarter)))^1.19 * (CLa_w_M/CLa_wing);
                                            CLa_body_corr = CLa_body * eta_body * (1 - dE_upwash);
                                            CLa_tail_corr = cos(Tail_dihedral) * CLa_tail * eta_h   * (1 - dE_down);
                                            

                                            
                                            % 4) total lift‐curve slope [per deg]
                                            a_total = (S_wing/S_ref)*CLa_wing                ...  % wing
                                                    + (S_body/S_ref)*CLa_body_corr           ...  % body
                                                    + (S_tail/S_ref)*CLa_tail_corr;             % tail
                                            
                                            % 5) effective zero‐lift angles [deg]
                                            %    wing: CLa_wing*(alpha + twist/2 - alpha0_wing) 
                                            %          => zero‐lift at alpha = alpha0_wing - twist/2
                                            alpha0_eff_wing = alpha0_wing - twist_wing/2;  
                                            alpha0_eff_body = alpha0_body - twist_body;
                                            %    body & tail use their geometric zero‐lift as before
                                            alpha0_total = (S_wing/S_ref)*alpha0_eff_wing  ...
                                                         + (S_body/S_ref)*alpha0_eff_body      ...
                                                         + (S_tail/S_ref)*alpha0_tail;         
                                            
                                            % 6) required CL to hold weight at cruise
                                            CL_req = 2 * W_TOTAL / (rho_cruise * V_max^2 * S_ref);
                                            
                                            % 7) solve for required angle of attack [deg]
                                            alpha_req = CL_req / a_total + alpha0_total;
                                            
                                        
                                            C_L_at_req = a_total * (alpha_req - alpha0_total);
                                            L_at_req   = 0.5 * rho_cruise * V_max^2 * S_ref * C_L_at_req;
                                            
                                            CL_req_cruise = 2 * W_TOTAL / (rho_cruise * 100^2 * S_ref);
                                            alpha_req_cruise = CL_req_cruise / a_total + alpha0_total;
                                            
                              
                                            C_L_at_cruise = a_total * (alpha_req_cruise - alpha0_total);
                                            L_at_rcruise   = 0.5 * rho_cruise * V_max^2 * S_ref * C_L_at_cruise;

                                            
                                            %% Weight Estimation Calculations
                                            W_blended_wing = 2.3 * (S_wing+S_body) * (w_skin + w_paint);
                                            W_tail_est = 2.2 * S_tail * (w_skin + w_paint);
                                            W_propulsion = n_engines * W_engine;
                                            W_external = W_blended_wing + W_tail_est + W_propulsion;
                                            
                                            %% Internal Weight Calculations
                                            y_wing = linspace((b - b_trans)/2, 0, num_longitudinal_spars_wing);
                                            c_wing_local = c_r - (c_t - c_r) * (abs(y_wing) / ((b - b_trans) / 2));
                                            area_wing_station = (2*normalized_area_wing) .* (c_wing_local.^2);
                                            total_area_wing = phi*sum(area_wing_station);
                                            
                                            % Body internal spar calculation
                                            y_body = linspace(-b_trans/2, -b_trans/3, num_longitudinal_spars_body);
                                            c_body_local = c_r + c_nose * (1 - (2 * abs(y_body) / b_trans));
                                            area_body_station = normalized_area_body .* (c_body_local.^2);
                                            total_area_body = phi_body*sum(area_body_station);
                                            
                                            total_aerofoil_area = total_area_body + total_area_wing;
                                            W_longitudinal_total = total_aerofoil_area * w_longitudinal_spar * t_long - 2*pi * r_spanwise_spar^2 * (num_spanwise_spars_body+num_spanwise_spars_wing);
                                            
                                            % Spanwise Spar Weight Calculations for the wing
                                            x1 = c_r; 
                                            x2 = ((b - b_trans) / 2) * tan(LE_sweep_rad) - c_t;
                                            x3 = ((b - b_trans) / 2) * tan(LE_sweep_rad);
                                            
                                            b1 = c_r * cot(LE_sweep_rad);
                                            b2 = c_t / tan(pi/2 - (pi/2 - atan(((b - b_trans) * tan(LE_sweep_rad) - c_r) / (b - b_trans))));
                                            
                                            x_wing_spar = linspace(0, (b - b_trans) / 2, num_spanwise_spars_wing);
                                            W_spanwise_spars_wing = 0;
                                            for idx = 1:length(x_wing_spar)
                                                x_val = x_wing_spar(idx);
                                                if x_val <= x1
                                                    b_local = x_val * cot(LE_sweep_rad);
                                                elseif x_val <= x2
                                                    b_local = b1 + (b2 - b1) / (x2 - x1) * (x_val - x1);
                                                elseif x_val <= x3
                                                    b_local = b2 + (0 - b2) / (x3 - x2) * (x_val - x2);
                                                else
                                                    b_local = 0;
                                                end
                                                W_spar_i = 2 * pi * r_spanwise_spar^2 * b_local * w_spanwise_spar;
                                                W_spanwise_spars_wing = W_spanwise_spars_wing + W_spar_i;
                                            end
                                            
                                            % Spanwise Spar Weight Calculations
                                            x_body_spar = linspace(0, c_nose + c_r, num_spanwise_spars_body);
                                            W_spanwise_spars_body = 0;
                                            for idx = 1:length(x_body_spar)
                                                x_val = x_body_spar(idx);
                                                if x_val < c_nose
                                                    b_local1 = (b_trans / c_nose) * x_val;
                                                else
                                                    b_local1 = b_trans;
                                                end
                                                W_spar_idx = pi * r_spanwise_spar^2 * b_local1 * w_spanwise_spar;
                                                W_spanwise_spars_body = W_spanwise_spars_body + W_spar_idx;
                                            end
                                            
                                            W_spanwise_total = W_spanwise_spars_body + W_spanwise_spars_wing;
                                            
                                                                                   
                                             % Leading‐Edge Spar Weight
                                            W_LE_spar = ...
                                                b_trans ./ sin(LE_lambda_body) ...                             % body LE spar term
                                              + (b - b_trans) ./ cos(LE_sweep_rad) ...                        % wing LE spar coefficient
                                                .* (r_LE_spar .^ 2) ...                                       % retain r^2 outside
                                                .* w_LE_spar;                                                 % retain w outside
                                            
                                            %% Trailing‐Edge Spar Weight (updated)
                                            W_TE_spar = ...
                                                ( b_trans ...
                                                + (b - b_trans) ./ sin(LE_sweep_rad) ) ...                    % flipped TE sweep term
                                                .* pi ...                                                     % π factor
                                                .* (r_TE_spar .^ 2) ...                                       % retain r^2 outside
                                                .* w_TE_spar;                                                 % retain w outside

                                            W_inlet_internal = (n_inlet_spars * phi_inlet * t_inlet_spars * w_inlet * depth_inlet + (w_skin + w_paint) * l_inlet) * 2 * h_inlet^2;
                                            
                                            W_internal = W_longitudinal_total + W_spanwise_total + W_inlet_internal + W_LE_spar + W_TE_spar;
                                            
                                            W_payload = 31.25;
                                            W_empty = W_external + W_internal + W_engine;
                                            W_total = W_empty + W_payload;
                                            
                                            %% Save Design Results (and save extra aerodynamic parameters)
                                            DesignCount = DesignCount + 1;
                                            Designs(DesignCount).V_max = V_max;
                                            Designs(DesignCount).n_max = n_max;
                                            Designs(DesignCount).W_external = W_external;
                                            Designs(DesignCount).W_internal = W_internal;
                                            Designs(DesignCount).W_empty = W_empty;
                                            Designs(DesignCount).W_total = W_total;
                                            Designs(DesignCount).W_longitudinal_total = W_longitudinal_total;
                                            Designs(DesignCount).b = b;
                                            Designs(DesignCount).c_r = c_r;
                                            Designs(DesignCount).b_trans = b_trans;
                                            Designs(DesignCount).LE_sweep_deg = LE_sweep_deg;
                                            Designs(DesignCount).taper_ratio = taper_ratio;
                                            Designs(DesignCount).c_nose = c_nose;
                                            Designs(DesignCount).LE_lambda_body = LE_lambda_body;  % Calculated value
                                            Designs(DesignCount).h_tail = h_tail;
                                            Designs(DesignCount).c_r_tail = c_r_tail;
                                            Designs(DesignCount).c_t_tail = c_t_tail;
                                            Designs(DesignCount).tail_sweep_deg = tail_sweep_deg;
                                            Designs(DesignCount).a_total = a_total;
                                            Designs(DesignCount).alpha_req = alpha_req;
                                            Designs(DesignCount).CL = CL_req;
                                            Designs(DesignCount).alpha_req_cruise = alpha_req_cruise;
                                            Designs(DesignCount).CL_req_cruise = CL_req_cruise;
                                           
                                            % --- Save extra aerodynamic parameters for envelope ---
                                            Designs(DesignCount).S_ref = S_ref;
                                            Designs(DesignCount).S_wing = S_wing;
                                            Designs(DesignCount).k_total = k_total;
                                            Designs(DesignCount).CD0_total = CD0_total;
                                            Designs(DesignCount).T_W_max = T_W_max;
                                            Designs(DesignCount).alpha_req = alpha_req;
                                                % … after computing S_wing and S_body, before incrementing DesignCount …
                                            Designs(DesignCount).S_wing = S_wing;
                                            Designs(DesignCount).S_body = S_body;
                                            Designs(DesignCount).W_blended_wing = W_blended_wing;
                                            Designs(DesignCount).W_LE_spar      = W_LE_spar;
                                            Designs(DesignCount).W_TE_spar      = W_TE_spar;
                                            % Save spanwise spar weights for verification:
                                            Designs(DesignCount).W_spanwise_body = W_spanwise_spars_body;
                                            Designs(DesignCount).W_spanwise_wing = W_spanwise_spars_wing;
                                            Designs(DesignCount).W_spanwise_total = W_spanwise_total;
                                            Designs(DesignCount).k_total  = k_total;
                                            Designs(DesignCount).alpha0_total = alpha0_total;
                                            Designs(DesignCount).MAC_body = MAC_body;
                                            Designs(DesignCount).MAC_wing = MAC_wing;


                                        end % if valid V_max
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

%% Filter Valid Designs and Display Results
validDesigns = Designs(1:DesignCount);
V_max_all     = [validDesigns.V_max];
n_max_all     = [validDesigns.n_max];
W_empty_all   = [validDesigns.W_empty];
W_total_all   = [validDesigns.W_total];
LE_lambda_body_all = [validDesigns.LE_lambda_body];
AoA_req_all = [validDesigns.alpha_req];
[~, idx_best] = max(V_max_all);
best = validDesigns(idx_best);
b_all      = [validDesigns.b];
S_wing_all = [validDesigns.S_wing];
S_body_all = [validDesigns.S_body];
b_all               = [validDesigns.b];
W_blended_wing_all  = [validDesigns.W_blended_wing];
b_all      = [validDesigns.b];
W_LE_all   = [validDesigns.W_LE_spar];
W_TE_all   = [validDesigns.W_TE_spar];

% ——— Build a table, sort by V_max, and take top 50 ———
T = struct2table(validDesigns);

% sort descending on V_max
T = sortrows(T, 'V_max', 'descend');

% pick the first 50 (or fewer, if you have <50 designs)
N = min(20, height(T));
Top50 = T(1:N, { ...
    'b', ...
    'c_r', ...
    'b_trans', ...
    'LE_sweep_deg', ...
    'taper_ratio', ...
    'c_nose', ...
    'V_max', ...               % maximum load factor
    'W_empty', ...             % empty weight
    'W_total'});

% display numeric matrix (rows = designs, cols = the 12 variables above)
TopMatrix = [ ...
    Top50.b, ...
    Top50.c_r, ...
    Top50.b_trans, ...
    Top50.LE_sweep_deg, ...
    Top50.taper_ratio, ...
    Top50.c_nose, ...
    Top50.V_max, ...
    Top50.W_empty, ...
    Top50.W_total];


% optional: also show the table for easier reading
disp('Detailed Table of Top 50 Designs:');
disp(Top50);



fprintf('Best Design (Highest V_max):\n');
fprintf('b = %.2f\n', best.b);
fprintf('b_{trans} = %.2f\n', best.b_trans);
fprintf('c_r = %.2f\n', best.c_r);
fprintf('LE_sweep = %.1f deg\n', best.LE_sweep_deg);
fprintf('Taper Ratio = %.2f\n', best.taper_ratio);
fprintf('c_{nose} = %.2f\n', best.c_nose);
fprintf('LE_{\lambda,body} (calculated) = %.2f\n', best.LE_lambda_body);
fprintf('Tail Sweep = %.1f deg\n', best.tail_sweep_deg);
fprintf('h_{tail} = %.2f\n', best.h_tail);
fprintf('c_{r tail} = %.2f\n', best.c_r_tail);
fprintf('c_{t tail} = %.2f\n', best.c_t_tail);
fprintf('V_{max} = %.2f m/s\n', best.V_max);
fprintf('n_{max} = %.2f\n', best.n_max);
fprintf('Empty Weight (W_e) = %.2f N\n', best.W_empty);
fprintf('Total Weight (W_e) = %.2f N\n', best.W_total);
fprintf('Total Lift Curve Slope (a_total) = %.2f\n', best.a_total);
fprintf('Required Angle of Attack (alpha_req) = %.2f deg\n', best.alpha_req);
fprintf('Coefficient of Lift (CL) = %.2f\n', best.CL);
fprintf('Required Angle of Attack at Cruise (alpha_req) = %.2f deg\n', best.alpha_req_cruise)
fprintf('\n--- Spar Weights for Best Design ---\n');
fprintf('Total Longitudinal Spar Weight = %.4f N\n', best.W_longitudinal_total);
fprintf('Body Spanwise Spar Weight = %.4f N\n', best.W_spanwise_body);
fprintf('Wing Spanwise Spar Weight = %.4f N\n', best.W_spanwise_wing);
fprintf('Total Spanwise Spar Weight = %.4f N\n', best.W_spanwise_total);
fprintf('Cl cruise: %.2f\n', CL_cruise);
fprintf('Cd0: %.2f\n',best.CD0_total);


%% Plotting and Analysis
figure;
histogram(V_max_all);
xlabel('V_{max} (m/s)');
ylabel('Frequency');
title('Frequency Histogram of V_{max}');

% Scatter plot: V_max vs Empty Weight (W_empty)
figure;
scatter(W_total_all, V_max_all, 'filled');
xlabel('Total Weight (N)');
ylabel('V_{max} (m/s)');
title('V_{max} vs Total Weight');

% Create subplots for V_max vs each design variable
b_all         = [validDesigns.b];
b_trans_all   = [validDesigns.b_trans];
c_r_all       = [validDesigns.c_r];
LE_sweep_all  = [validDesigns.LE_sweep_deg];
taper_all     = [validDesigns.taper_ratio];
c_nose_all    = [validDesigns.c_nose];
tail_sweep_all = [validDesigns.tail_sweep_deg];
h_tail_all    = [validDesigns.h_tail];
c_r_tail_all  = [validDesigns.c_r_tail];
c_t_tail_all  = [validDesigns.c_t_tail];

figure;
subplot(3,3,1);
scatter(b_all, V_max_all, 'filled');
xlabel('b');
ylabel('V_{max}');
title('V_{max} vs b');

subplot(3,3,2);
scatter(b_trans_all, V_max_all, 'filled');
xlabel('b_{trans}');
ylabel('V_{max}');
title('V_{max} vs b_{trans}');

subplot(3,3,3);
scatter(c_r_all, V_max_all, 'filled');
xlabel('c_r');
ylabel('V_{max}');
title('V_{max} vs c_r');

subplot(3,3,4);
scatter(LE_sweep_all, V_max_all, 'filled');
xlabel('LE Sweep (deg)');
ylabel('V_{max}');
title('V_{max} vs LE Sweep');

subplot(3,3,5);
scatter(taper_all, V_max_all, 'filled');
xlabel('Taper Ratio');
ylabel('V_{max}');
title('V_{max} vs Taper Ratio');

subplot(3,3,6);
scatter(c_nose_all, V_max_all, 'filled');
xlabel('c_{nose}');
ylabel('V_{max}');
title('V_{max} vs c_{nose}');

subplot(3,3,7);
scatter(tail_sweep_all, V_max_all, 'filled');
xlabel('Tail Sweep (deg)');
ylabel('V_{max}');
title('V_{max} vs Tail Sweep');

subplot(3,3,8);
scatter(h_tail_all, V_max_all, 'filled');
xlabel('h_{tail}');
ylabel('V_{max}');
title('V_{max} vs h_{tail}');

subplot(3,3,9);
scatter(c_r_tail_all, V_max_all, 'filled');
xlabel('c_{r tail}');
ylabel('V_{max}');
title('V_{max} vs c_{r tail}');

%% Plot LE_lambda_body vs V_max
figure;
scatter(V_max_all, LE_lambda_body_all, 'filled');
xlabel('V_{max} (m/s)');
ylabel('LE_{\lambda,body}');
title('LE_{\lambda,body} vs V_{max}');
grid on;

%% Load Factor Envelope Plot for Best Design
g = 9.81;        % gravitational acceleration [m/s^2]
CL_max = 0.75;    % maximum lift coefficient

% Use aerodynamic parameters from best design for envelope calculations.
WS_best = W_TOTAL / best.S_ref; % Wing loading for envelope
T_W_best = best.T_W_max;        % Thrust-to-weight ratio
k_best = best.k_total;
CD0_best = best.CD0_total;

% Define a velocity range for envelope analysis
V_env = linspace(10, 400, 500);
q_env = 0.5 * rho_cruise .* V_env.^2;  % dynamic pressure

% Compute the n_max envelope for the best design
n_max_env = sqrt( 1 + (q_env ./ (k_best * WS_best)) .* (T_W_best - q_env .* (CD0_best ./ WS_best)) );

% Compute stall boundary using CL_max
n_stall_env = (q_env * CL_max) ./ WS_best;

% Plot the envelope for the best design
figure;
hold on;
grid on;
plot(V_env, n_max_env, 'k-', 'LineWidth', 2);    % Envelope n_max
plot(V_env, n_stall_env, 'b--', 'LineWidth', 2);    % Stall boundary
yline(8, 'Color', [0.5 0 0], 'LineStyle', '--', 'LineWidth', 2, ...
      'Label', 'n = 8g Limit', 'LabelVerticalAlignment', 'bottom');
xlabel('Velocity, V (m/s)');
ylabel('Load Factor, n');
title('Load Factor Envelope for Best Design');
legend({'n_{max} (Envelope)', 'Stall Boundary', 'n = 8g Limit'}, 'Location', 'NorthEast');
ylim([0, 15]);
xlim([0, 170]);

figure;
scatter([validDesigns.V_max], AoA_req_all, 'filled');
xlabel('V_{max} (m/s)');
ylabel('\alpha_{req} (deg)');
title('Required Angle of Attack vs Maximum Speed');
grid on;

% Extract V_max and W_total from the Top50 table
V_max_top50 = Top50.V_max;
W_total_top50 = Top50.W_total;

% Create scatter plot
figure;
scatter(W_total_top50, V_max_top50, 'filled', 'MarkerFaceAlpha', 0.7);
hold on;

% Annotate plot
xlabel('Total Weight W_{total} (N)');
ylabel('Maximum Velocity V_{max} (m/s)');
title('V_{max} vs W_{total} for Top 50 Designs');
grid on;
hold off;


% For minimum‐radius turn you need V_star:
V_star     = 110.4;   % m/s
n_max = 8;
rho = 1.225;
N_max2 = 5;
V_star2 = 87.37;

%% — Corner velocity (best maneuvering speed) — 
V_corner = sqrt( (2*n_max)/(rho*CL_max) * (WS_best) );
r_turn_min2 = V_star2.^2 ./ ( g * sqrt( N_max2.^2 - 1 ) );


%% — Maximum turn‐rate (at corner speed & n_max) — 
omega_turn_max = rad2deg(g * sqrt(n_max^2 - 1) / V_corner);

%% — Minimum turn‐radius (at V_star & n_max) — 
%   Note: eqn given as r = V*^2 / (g/√(n_max^2–1))
r_turn_min = V_star.^2 ./ ( g ./ sqrt(n_max^2 - 1) );

%% — Maximum bank angle — 
theta_max = rad2deg(acos( 1 / n_max ));

vals = [V_corner, V_star,V_star2,N_max2, omega_turn_max, r_turn_min, theta_max,r_turn_min2];

T = array2table(vals, ...
    'VariableNames',{'V_corner','V_star','V_star2','n_max2','omega_max','r_min','theta_max','r_turn_min2'});

disp(T);

% Speed range (m/s)
V = linspace(10, 200, 500);

% Climb rate calculation
v_c = V .* (T_available./W_total - 0.5 .* rho .* V.^2 .* (S_ref./W_total) .* CD0_best - (W_total./S_ref) .* (2 .* k_total) ./ (rho .* V.^2));

% Plotting
figure;
plot(V, v_c, 'LineWidth', 1.5);
grid on;
xlabel('Speed V (m/s)');
ylabel('Climb Rate v_c (m/s)');
title('Climb Rate vs. Speed');

%% Ground roll calcualtion


mu = 0.04;

thrust = 480;      

% Define CL and CD at the reduced speed (you can also make these functions of V):
CL_at_Vred = 0.713;
CD_at_Vred = 0.056;

%% ----- STEP 1: Compute Rotation Speed V_R -----
V_R = 1.556 * sqrt( W_total / (rho * S_ref * CL_max) );
fprintf('Rotation speed: V_R = %.2f m/s (%.1f kt)\n', ...
        V_R, V_R*1.94384);

%% ----- STEP 2: Reduced Rotation Speed V_red -----
V_red = V_R / sqrt(2);

%% ----- STEP 3: Thrust at Reduced Rotation Speed -----
T_red = thrust;
fprintf('Thrust at V_R/√2: T = %.0f N\n', T_red);

%% ----- Lift and Drag at V_red -----
L_red = 0.5 * rho * V_red^2 * S_ref * CL_at_Vred;
D_red = 0.5 * rho * V_red^2 * S_ref * CD_at_Vred;

fprintf('Lift at V_R/√2: L = %.0f N\n', L_red);
fprintf('Drag at V_R/√2: D = %.0f N\n', D_red);

%% ----- STEP 4: Ground Run S_G -----
% using S_G = V_R^2 * W  / [ 2 g ( T - D - μ (W - L) ) ]  at V=V_R/√2
denom = 2*g*( T_red - D_red - mu*(W_total - L_red) );
S_G   = V_R^2 * W_total / denom;

fprintf('Ground‐run distance S_G = %.1f m\n', S_G);
results = [ V_R, S_G ];

disp('  [ V_R (m/s) ,  S_G (m) ]');
disp(results);