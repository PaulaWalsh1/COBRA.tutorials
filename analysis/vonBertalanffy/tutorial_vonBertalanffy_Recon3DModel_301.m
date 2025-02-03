%% Thermodynamically constrain a Recon3D
%% *Author: Ronan Fleming, Leiden University*
%% *Reviewers:* 
%% INTRODUCTION
% In flux balance analysis of genome scale stoichiometric models of metabolism, 
% the principal constraints are uptake or secretion rates, the steady state mass 
% conservation assumption and reaction directionality. Von Bertylanffy [1,4] is 
% a set of methods for (i) quantitative estimation of thermochemical parameters 
% for metabolites and reactions using the component contribution method [3], (ii) 
% quantitative assignment of reaction directionality in a multi-compartmental 
% genome scale model based on an application of the second law of thermodynamics 
% to each reaction [2], (iii) analysis of thermochemical parameters in a network 
% context, and (iv) thermodynamically constrained flux balance analysis. The theoretical 
% basis for each of these methods is detailed within the cited papers.
%% PROCEDURE
%% Configure the environment
% The default COBRA Toolbox paths are automatically changed here to work on 
% the new version of vonBertalanffy

aPath = which('initVonBertalanffy');
basePath = strrep(aPath,['vonBertalanffy' filesep 'initVonBertalanffy.m'],'');
addpath(genpath(basePath))
folderPattern=[filesep 'old'];
method = 'remove';
editCobraToolboxPath(basePath,folderPattern,method)
aPath = which('initVonBertalanffy');
basePath = strrep(aPath,['vonBertalanffy' filesep 'initVonBertalanffy.m'],'');
addpath(genpath(basePath))
folderPattern=[filesep 'new'];
method = 'add';
editCobraToolboxPath(basePath,folderPattern,method)
%% 
% All the installation instructions are in a separate .md file named vonBertalanffy.md 
% in docs/source/installation
% 
% With all dependencies installed correctly, we configure our environment, verfy 
% all dependencies, and add required fields and directories to the matlab path.

initVonBertalanffy
%% Select the model
% This tutorial is tested for the E. coli model iAF1260 and the human metabolic 
% model Recon3Dmodel. However, only the data for the former is provided within 
% the COBRA Toolbox as it is used for testing von Bertylanffy. However, the figures 
% generated below are most suited to plotting results for Recon3D, so they may 
% not be so useful for iAF1260.  The Recon3D example uses values from literature 
% for input variables where they are available.

%modelName = 'iAF1260';
%modelName='Ec_iAF1260_flux1'; 
% uncomment this line and comment the line below if you want to use the other model-  currently will not work without changes
modelName='Recon3DModel_301'; 
%% Load a model
% Load a model, and save it as the original model in the workspace, unless it 
% is already loaded into the workspace. 

clear model
global CBTDIR
modelFileName = [modelName '.mat']


modelDirectory = getDistributedModelFolder(modelFileName); %Look up the folder for the distributed Models.
modelFileName= [modelDirectory filesep modelFileName]; % Get the full path. Necessary to be sure, that the right model is loaded

switch modelName
    case 'Ec_iAF1260_flux1'
        modelFileName = [modelName '.xml']
        model = readCbModel(modelFileName);
        if model.S(952, 350)==0
            model.S(952, 350)=1; % One reaction needing mass balancing in iAF1260
        end
        model.metCharges(strcmp('asntrna[Cytosol]', model.mets))=0; % One reaction needing charge balancing
        
    case 'iAF1260'
        model = readCbModel(modelFileName);
        model.mets = cellfun(@(mets) strrep(mets,'_c','[c]'),model.mets,'UniformOutput',false);
        model.mets = cellfun(@(mets) strrep(mets,'_e','[e]'),model.mets,'UniformOutput',false);
        model.mets = cellfun(@(mets) strrep(mets,'_p','[p]'),model.mets,'UniformOutput',false);
        bool = strcmp(model.mets,'lipa[c]old[c]');
        model.mets{bool}='lipa_old_[c]';
        bool = strcmp(model.mets,'lipa[c]old[e]');
        model.mets{bool}='lipa_old_[e]';
        bool = strcmp(model.mets,'lipa[c]old[p]');
        model.mets{bool}='lipa_old_[p]';
        if model.S(952, 350)==0
            model.S(952, 350)=1; % One reaction needing mass balancing in iAF1260
        end
        model.metCharges(strcmp('asntrna[c]', model.mets))=0; % One reaction needing charge balancing
        
    case 'Recon3DModel_Dec2017'
      model = readCbModel(modelFileName);
      model.csense(1:size(model.S,1),1)='E';
      %Hack for thermodynamics
      model.metFormulas{strcmp(model.mets,'h[i]')}='H';
      model.metFormulas(cellfun('isempty',model.metFormulas)) = {'R'};
      if isfield(model,'metCharge')
          model.metCharges = double(model.metCharge);
          model=rmfield(model,'metCharge');
      end
      modelOrig = model;
   case 'Recon3DModel_301'
      model = readCbModel(modelFileName);
          %Hack for thermodynamics
      model.metFormulas(cellfun('isempty',model.metFormulas)) = {'R'};
      modelOrig = model;
    otherwise
            error('setup specific parameters for your model')
end
%% Set the directory containing the results

switch modelName
    case 'Ec_iAF1260_flux1'
        resultsPath=which('tutorial_vonBertalanffy.mlx');
        resultsPath=strrep(resultsPath,'/tutorial_vonBertalanffy.mlx','');
        resultsPath=[resultsPath filesep modelName '_results'];
        resultsBaseFileName=[resultsPath filesep modelName '_results'];
    case 'iAF1260'
        resultsPath=which('tutorial_vonBertalanffy.mlx');
        resultsPath=strrep(resultsPath,'/tutorial_vonBertalanffy.mlx','');
        resultsPath=[resultsPath filesep modelName '_results'];
        resultsBaseFileName=[resultsPath filesep modelName '_results'];
    case 'Recon3DModel_Dec2017'
        basePath='~/work/sbgCloud';
        resultsPath=[basePath '/programReconstruction/projects/recon2models/results/thermo/' modelName];
        resultsBaseFileName=[resultsPath filesep modelName '_' datestr(now,30) '_'];
    case 'Recon3DModel_301'
        basePath=['~' filesep 'work' filesep 'sbgCloud'];
        resultsPath=which('tutorial_vonBertalanffy.mlx');
        resultsPath=strrep(resultsPath,[filesep 'tutorial_vonBertalanffy.mlx'],'');
        resultsPath=[resultsPath filesep modelName '_results'];
        resultsBaseFileName=[resultsPath filesep modelName '_results_'];
    otherwise
        error('setup specific parameters for your model')
end
%% Set the directory containing molfiles

switch modelName
    case 'Ec_iAF1260_flux1'
        molFileDir = 'iAF1260Molfiles';
    case 'iAF1260'
        molFileDir = 'iAF1260Molfiles';
    case 'Recon3DModel_Dec2017'
        molFileDir = [basePath '/data/metDatabase/explicit/molFiles'];
        %molFileDir = [basePath '/programModelling/projects/atomMapping/results/molFilesDatabases/DBimplicitHMol'];
        %molFileDir = [basePath '/programModelling/projects/atomMapping/results/molFilesDatabases/DBexplicitHMol'];
    case 'Recon3DModel_301'
        ctfPath = [basePath filesep 'code' filesep 'fork-ctf'];
        % system(['git clone https://github.com/opencobra/ctf' ctfPath])
        molFileDir = [basePath filesep 'code' filesep 'fork-ctf' filesep 'mets' filesep 'molFiles'];
    otherwise
        molFileDir = [basePath '/code/fork-ctf/mets/molFiles'];
end
%% Set the thermochemical parameters for the model

switch modelName
    case 'Ec_iAF1260_flux1'
        T = 310.15; % Temperature in Kelvin
        compartments = {'Cytosol'; 'Extra_organism'; 'Periplasm'}; % Cell compartment identifiers
        ph = [7.7; 7.7; 7.7]; % Compartment specific pH
        is = [0.25; 0.25; 0.25]; % Compartment specific ionic strength in mol/L
        chi = [0; 90; 90]; % Compartment specific electrical potential relative to cytosol in mV        
    case 'iAF1260'
        T = 310.15; % Temperature in Kelvin
        compartments = ['c'; 'e'; 'p']; % Cell compartment identifiers
        ph = [7.7; 7.7; 7.7]; % Compartment specific pH
        is = [0.25; 0.25; 0.25]; % Compartment specific ionic strength in mol/L
        chi = [0; 90; 90]; % Compartment specific electrical potential relative to cytosol in mV
    case 'Recon3DModel_Dec2017'
        % Temperature in Kelvin
        T = 310.15; 
        % Cell compartment identifiers
        compartments = ['c'; 'e'; 'g'; 'l'; 'm'; 'n'; 'r'; 'x';'i']; 
        % Compartment specific pH
        ph = [7.2; 7.4; 6.35; 5.5; 8; 7.2; 7.2; 7; 7.2]; 
        % Compartment specific ionic strength in mol/L
        is = 0.15*ones(length(compartments),1); 
        % Compartment specific electrical potential relative to cytosol in mV
        chi = [0; 30; 0; 19; -155; 0; 0; -2.303*8.3144621e-3*T*(ph(compartments == 'x') - ph(compartments == 'c'))/(96485.3365e-6); 0]; 
    case 'Recon3DModel_301'
        % Temperature in Kelvin
        T = 310.15; 
        % Cell compartment identifiers
        compartments = ['c'; 'e'; 'g'; 'l'; 'm'; 'n'; 'r'; 'x';'i']; 
        % Compartment specific pH
        ph = [7.2; 7.4; 6.35; 5.5; 8; 7.2; 7.2; 7; 7.2]; 
        % Compartment specific ionic strength in mol/L
        is = 0.15*ones(length(compartments),1); 
        % Compartment specific electrical potential relative to cytosol in mV
        chi = [0; 30; 0; 19; -155; 0; 0; -2.303*8.3144621e-3*T*(ph(compartments == 'x') - ph(compartments == 'c'))/(96485.3365e-6); 0]; 
    otherwise
        error('setup specific parameters for your model')
end
%% Set the default range of metabolite concentrations

switch modelName
    case 'Ec_iAF1260_flux1'
        concMinDefault = 1e-5; % Lower bounds on metabolite concentrations in mol/L
        concMaxDefault = 0.02; % Upper bounds on metabolite concentrations in mol/L
        metBoundsFile=[];
    case 'iAF1260'
        concMinDefault = 1e-5; % Lower bounds on metabolite concentrations in mol/L
        concMaxDefault = 0.02; % Upper bounds on metabolite concentrations in mol/L
        metBoundsFile=[];
    case 'Recon3DModel_Dec2017'
        concMinDefault=1e-5; % Lower bounds on metabolite concentrations in mol/L
        concMaxDefault=1e-2; % Upper bounds on metabolite concentrations in mol/L
        metBoundsFile=which('HumanCofactorConcentrations.txt');%already in the COBRA toolbox
    case 'Recon3DModel_301'
        concMinDefault=1e-5; % Lower bounds on metabolite concentrations in mol/L
        concMaxDefault=1e-2; % Upper bounds on metabolite concentrations in mol/L
        metBoundsFile=which('HumanCofactorConcentrations.txt');%already in the COBRA toolbox
    otherwise
        error('setup specific parameters for your model')
end
%% Set the desired confidence level for estimation of thermochemical parameters
% The confidence level for estimated standard transformed reaction Gibbs energies 
% is used to quantitatively assign reaction directionality.

switch modelName
    case 'Ec_iAF1260_flux1'
        confidenceLevel = 0.95; 
        DrGt0_Uncertainty_Cutoff = 20; %KJ/KMol    
    case 'iAF1260'
        confidenceLevel = 0.95; 
        DrGt0_Uncertainty_Cutoff = 20; %KJ/KMol
    case 'Recon3DModel_Dec2017'
        confidenceLevel = 0.95;
        DrGt0_Uncertainty_Cutoff = 20; %KJ/KMol
    otherwise
        confidenceLevel = -1;%bypass addition of uncertainty temporarily
        %confidenceLevel = 0.95;
        DrGt0_Uncertainty_Cutoff = 20; %KJ/KMol
end
%% Prepare folder for results

if ~exist(resultsPath,'dir')
    mkdir(resultsPath)
end
cd(resultsPath)
%% Set the print level and decide to record a diary or not (helpful for debugging)

printLevel=2;

diary([resultsPath filesep 'diary.txt'])
%% Setup a thermodynamically constrained model
%% Read in the metabolite bounds

setDefaultConc=1;
setDefaultFlux=0;
rxnBoundsFile=[];
model=readMetRxnBoundsFiles(model,setDefaultConc,setDefaultFlux,concMinDefault,concMaxDefault,metBoundsFile,rxnBoundsFile,printLevel);
%% Check inputs

model = configureSetupThermoModelInputs(model,T,compartments,ph,is,chi,concMinDefault,concMaxDefault,confidenceLevel);
%% Add InChI to model

%[model, pKaErrorMets] = setupComponentContribution(model,molFileDir);
model = addInchiToModel(model, molFileDir, 'sdf', printLevel);
%% Add pseudoisomers to model

[model, nonphysicalMetBool, pKaErrorMetBool] = addPseudoisomersToModel(model, printLevel);
% Check elemental balancing of metabolic reactions

ignoreBalancingOfSpecifiedInternalReactions=1;
if ~exist('massImbalance','var')
    if isfield(model,'Srecon')
        model.S=model.Srecon;
    end
    % Check for imbalanced reactions
    fprintf('\nChecking mass and charge balance.\n');
    %Heuristically identify exchange reactions and metabolites exclusively involved in exchange reactions
    if ~isfield(model,'SIntMetBool')  ||  ~isfield(model,'SIntRxnBool') || ignoreBalancingOfSpecifiedInternalReactions
        %finds the reactions in the model which export/import from the model
        %boundary i.e. mass unbalanced reactions
        %e.g. Exchange reactions
        %     Demand reactions
        %     Sink reactions
        model = findSExRxnInd(model,[],printLevel);
    end
    
    if ignoreBalancingOfSpecifiedInternalReactions
        [nMet,nRxn]=size(model.S);
        ignoreBalancingMetBool=false(nMet,1);
        for m=1:nMet
%             if strcmp(model.mets{m},'Rtotal3coa[m]')
%                 pause(0.1);
%             end
            if ~isempty(model.metFormulas{m})
                ignoreBalancingMetBool(m,1)=numAtomsOfElementInFormula(model.metFormulas{m},'FULLR');
            end
        end
        ignoreBalancingRxnBool=getCorrespondingCols(model.S,ignoreBalancingMetBool,model.SIntRxnBool,'inclusive');
        SIntRxnBool=model.SIntRxnBool;
        model.SIntRxnBool=model.SIntRxnBool & ~ignoreBalancingRxnBool;
    end
    
    printLevelcheckMassChargeBalance=-1;  % -1; % print problem reactions to a file
    %mass and charge balance can be checked by looking at formulas
    [massImbalance,imBalancedMass,imBalancedCharge,imBalancedRxnBool,Elements,missingFormulaeBool,balancedMetBool]...
        = checkMassChargeBalance(model,printLevelcheckMassChargeBalance,resultsBaseFileName);
    model.balancedRxnBool=~imBalancedRxnBool;
    model.balancedMetBool=balancedMetBool;
    model.Elements=Elements;
    model.missingFormulaeBool=missingFormulaeBool;
    
    %reset original boolean vector
    if ignoreBalancingOfSpecifiedInternalReactions
        model.SIntRxnBool=SIntRxnBool;
    end
end
%% 
%% Create the thermodynamic training model

if 1
    %use previously generated training model
    aPath = which('driver_createTrainingModel.mlx');
    aPath = strrep(aPath,['new' filesep 'driver_createTrainingModel.mlx'],['cache' filesep]);
    load([aPath 'trainingModel.mat'])
else
    %recreate the trainingModel
    driver_createTrainingModel
end
%%
figure
histogram(trainingModel.DrGt0)
title('$Experimental \smallskip \Delta_{r} G^{\prime0}$','Interpreter','latex')
ylabel('KJ/Mol')
fprintf('%u%s\n',nnz(trainingModel.DrGt0==0),' = number of zero DrGt0, i.e. experimental apparent equilibrium constant equal to one') 
formulas = printRxnFormula(trainingModel,trainingModel.rxns(trainingModel.DrGt0==0));
figure
histogram(trainingModel.DrG0)
title('$Experimental \medskip \Delta_{r} G^{0}$','Interpreter','latex')
ylabel('KJ/Mol')
fprintf('%u%s\n',nnz(trainingModel.DrG0==0),' = number of zero DrG0. i.e. equilibrium constant equal to one and same number of hydrogens on both sides') 
formulas = printRxnFormula(trainingModel,trainingModel.rxns(trainingModel.DrG0==0));

%% Create Group Incidence Matrix
% Create the group incidence matrix (G) for the combined set of all metabolites.

save('data_prior_to_createGroupIncidenceMatrix')
%%
%param.fragmentationMethod='manual';
param.fragmentationMethod='abinito';
param.printLevel=0;
param.modelCache=['autoFragment_' modelName];
param.debug=1;
param.radius=2;
%%
combinedModel = createGroupIncidenceMatrix(model, trainingModel, param);
%%
fprintf('%u%s\n',nnz(combinedModel.trainingMetBool),' = number of training metabolites')
fprintf('%u%s\n',nnz(combinedModel.trainingMetBool & combinedModel.groupDecomposableBool),' ... of which are group decomposable.')
fprintf('%u%s\n',nnz(combinedModel.trainingMetBool & ~combinedModel.inchiBool),' ... of which have no inchi.')
fprintf('%u%s\n',nnz(combinedModel.trainingMetBool & combinedModel.inchiBool & ~combinedModel.groupDecomposableBool),' ... of which are not group decomposable.')
fprintf('%u%s\n',nnz(combinedModel.testMetBool),' = number of test metabolites')
fprintf('%u%s\n',nnz(combinedModel.testMetBool & combinedModel.groupDecomposableBool),' ... of which are group decomposable.')
fprintf('%u%s\n',nnz(combinedModel.testMetBool & ~combinedModel.inchiBool),' ... of which have no inchi.')
fprintf('%u%s\n',nnz(combinedModel.testMetBool & combinedModel.inchiBool & ~combinedModel.groupDecomposableBool),' ... of which are not group decomposable.')
fprintf('%u%s\n',size(combinedModel.S,1),' combined model metabolites.')
fprintf('%u%s\n',nnz(combinedModel.trainingMetBool & ~combinedModel.testMetBool),' ... of which are exclusively training metabolites.')
fprintf('%u%s\n',nnz(combinedModel.trainingMetBool & combinedModel.testMetBool),' ... of which are both training and test metabolites.')
fprintf('%u%s\n',nnz(~combinedModel.trainingMetBool & combinedModel.testMetBool),' ... of which are exclusively test metabolites.')
save('data_prior_to_componentContribution','model','combinedModel')
%% Apply component contribution method

if ~isfield(model,'DfG0')
    [model,solution] = componentContribution(model,combinedModel);
end
%%
figure
histogram(solution.DfG0_rc)
title('$\textrm{Reactant contribution } \Delta_{f} G^{0}_{rc}$','Interpreter','latex')
ylabel('KJ/Mol')
fprintf('%u%s\n',nnz(isnan(solution.DfG0_rc)),' formation energies')
fprintf('%u%s\n',nnz(isnan(solution.DfG0_rc)),' of which DfG0_rc(j) are NaN. i.e., number of formation energies that cannot be estimated by reactant contribution')
fprintf('%g%s\n',nnz(isnan(solution.DfG0_rc))/length(solution.DfG0_rc),' = fraction of DfG0_rc(j)==NaN')
figure
histogram(solution.DfG0_gc)
title('$\textrm{Group formation energies } \Delta_{f} G^{0}_{gc}$','Interpreter','latex')
ylabel('KJ/Mol')
fprintf('%u%s\n',length(solution.DfG0_gc),' estimated group formation energies')
fprintf('%u%s\n',nnz(isnan(solution.DfG0_gc)),' of which have DfG0_gc(j)==NaN. i.e., number of formation energies that cannot be estimated by group contribution')
fprintf('%g%s\n',nnz(isnan(solution.DfG0_gc))/length(solution.DfG0_gc),' fraction of DfG0_gc(j)==NaN')
figure
histogram(solution.DfG0_cc)
title('$\textrm{Component contribution } \Delta_{f} G^{0}_{cc}$','Interpreter','latex')
ylabel('KJ/Mol')
fprintf('%u%s\n',length(solution.DfG0_cc),' estimated reactant formation energies.')
fprintf('%u%s\n',nnz(isnan(solution.DfG0_cc)),' of which have DfG0_cc(j)==NaN. i.e., number of formation energies that cannot be estimated by component contribution')
fprintf('%g%s\n',nnz(isnan(solution.DfG0_cc))/length(solution.DfG0_cc),' = fraction of zero DfG0_cc')
fprintf('%u%s\n',length(model.DfGt0),' model metabolites') 
fprintf('%u%s\n',nnz(isnan(model.DfGt0)),' of which are DfG0_cc(j)==NaN. i.e., number of formation energies that cannot be estimated by component contribution')
fprintf('%g%s\n',nnz(isnan(model.DfG0_cc))/length(model.DfG0_cc),' = fraction of zero DfG0_cc')

figure
histogram(model.DrG0)
title('$\Delta_{r} G^{0}_{cc}$','Interpreter','latex')
ylabel('KJ/Mol')
fprintf('%u%s\n',length(model.DrG0),' model reactions') 
fprintf('%u%s\n',nnz(isnan(model.DrG0)),' of which have DrG0(j)==NaN. i.e. estimated equilibrium constant equal to one') 
formulas = printRxnFormula(model,model.rxns(isnan(model.DrG0)));

%% Setup a thermodynamically constrained model

save('debug_prior_to_setupThermoModel')
%%
if ~isfield(model,'DfGt0')
    model = setupThermoModel(model,confidenceLevel);
end
%%
figure
histogram(model.DfGt0)
title('$\Delta_{f} G^{0\prime}_{cc}$','Interpreter','latex')
ylabel('KJ/Mol')

%% Generate a model with reactants instead of major microspecies

if ~isfield(model,'Srecon') 
    printLevel_pHbalanceProtons=-1;
    model=pHbalanceProtons(model,massImbalance,printLevel_pHbalanceProtons,resultsBaseFileName);
end
%% Determine quantitative directionality assignments

if ~exist('directions','var') |  1
    fprintf('Quantitatively assigning reaction directionality.\n');
    [model, directions] = thermoConstrainFluxBounds(model,confidenceLevel,DrGt0_Uncertainty_Cutoff,printLevel);
end
%% Analyse thermodynamically constrained model
% Choose the cutoff for probablity that reaction is reversible

cumNormProbCutoff=0.2;
%% 
% Build Boolean vectors with reaction directionality statistics

[model,directions]=directionalityStats(model,directions,cumNormProbCutoff,printLevel);
% directions    a structue of boolean vectors with different directionality
%               assignments where some vectors contain subsets of others
%
% qualtiative -> quantiative changed reaction directions
%   .forward2Forward
%   .forward2Reverse
%   .forward2Reversible
%   .forward2Uncertain
%   .reversible2Forward
%   .reversible2Reverse
%   .reversible2Reversible
%   .reversible2Uncertain
%   .reverse2Forward
%   .reverse2Reverse
%   .reverse2Reversible
%   .reverse2Uncertain
%   .tightened
%
% subsets of qualtiatively forward  -> quantiatively reversible 
%   .forward2Reversible_bydGt0
%   .forward2Reversible_bydGt0LHS
%   .forward2Reversible_bydGt0Mid
%   .forward2Reversible_bydGt0RHS
% 
%   .forward2Reversible_byConc_zero_fixed_DrG0
%   .forward2Reversible_byConc_negative_fixed_DrG0
%   .forward2Reversible_byConc_positive_fixed_DrG0
%   .forward2Reversible_byConc_negative_uncertain_DrG0
%   .forward2Reversible_byConc_positive_uncertain_DrG0
%% 
% Write out reports on directionality changes for individual reactions to the 
% results folder.

fprintf('%s\n','directionalityChangeReport...');
directionalityChangeReport(model,directions,cumNormProbCutoff,printLevel,resultsBaseFileName)
%% 
% Generate pie charts with proportions of reaction directionalities and changes 
% in directionality

fprintf('%s\n','directionalityStatFigures...');
directionalityStatsFigures(directions,resultsBaseFileName)
%% 
% Generate figures to interpret the overall reasons for reaction directionality 
% changes for the qualitatively forward now quantiatiavely reversible reactions

if any(directions.forward2Reversible)
    fprintf('%s\n','forwardReversibleFigures...');
    forwardReversibleFigures(model,directions,confidenceLevel)
end
%% 
% Write out tables of experimental and estimated thermochemical parameters for 
% the model

generateThermodynamicTables(model,resultsBaseFileName);
save([datestr(now,30) '_' modelName '_thermo'],'model')
save([datestr(now,30) '_vonB_tutorial_complete'])
%% 
% *REFERENCES*
% 
% [1] Fleming, R. M. T. & Thiele, I. von Bertalanffy 1.0: a COBRA toolbox extension 
% to thermodynamically constrain metabolic models. Bioinformatics 27, 142–143 
% (2011).
% 
% [2] Haraldsdóttir, H. S., Thiele, I. & Fleming, R. M. T. Quantitative assignment 
% of reaction directionality in a multicompartmental human metabolic reconstruction. 
% Biophysical Journal 102, 1703–1711 (2012).
% 
% [3] Noor, E., Haraldsdóttir, H. S., Milo, R. & Fleming, R. M. T. Consistent 
% Estimation of Gibbs Energy Using Component Contributions. PLoS Comput Biol 9, 
% e1003098 (2013).
% 
% [4] Fleming, R. M. T. , Predicat, G.,  Haraldsdóttir, H. S., Thiele, I. von 
% Bertalanffy 2.0 (in preparation).