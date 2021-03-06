function configGenerator(param)

% Generate config file

% Open config file for writing
fid = fopen('../TopLevelDecoder/config.vhdl', 'wt');

fprintf(fid,'library ieee;\n');
fprintf(fid,'use ieee.std_logic_1164.all;\n');
fprintf(fid,'use ieee.numeric_std.all;\n');
fprintf(fid,'use ieee.math_real.all;\n');
fprintf(fid,'library work;\n\n');
fprintf(fid,'package config is\n\n');

%% General parameters

fprintf(fid,'------ General Parameters -----\n');

fprintf(fid,['-- Number of variable nodes\n' ...
    'constant N : integer := %d;\n\n' ...
    '-- Number of check nodes\n' ...
    'constant M : integer := %d;\n\n'], param.N, param.M);

fprintf(fid,'-- Number of decoding iterations\n');
fprintf(fid,'constant iter : integer := %d;\n\n', param.maxIter);

fprintf(fid,'-- LLR bit-widths\n');
fprintf(fid,'constant QLLR : integer := %d;\n', param.QLLR);
fprintf(fid,'constant QCh : integer := %d;\n\n', param.QCh);


%% Variable nodes
fprintf(fid,'------ Variable Nodes -----\n');
fprintf(fid,'-- Variable node degree\n');
fprintf(fid,'constant VNodeDegree : integer := %d;\n\n', param.VNodeDegree);

fprintf(fid,'-- Channel LLR type\n');
fprintf(fid,'subtype ChLLRType is integer range 0 to 2**QCh-1;\n');
fprintf(fid,'type ChLLRTypeStage is array(0 to N-1) of ChLLRType;\n\n');

fprintf(fid,'-- Internal LLR type\n');
fprintf(fid,'subtype IntLLRSubType is integer range 0 to 2**QLLR-1;\n');
fprintf(fid,'type IntLLRTypeV is array (0 to VNodeDegree-1) of IntLLRSubType;\n\n');

%% Generate LUTs
fprintf(fid,'------ LUTs ------\n');

% Convert from channel LLR bit-width to check node bit-width for first check node
fprintf(fid,'constant LUTInputBits_QCh_to_Qmsg : integer := %d;\n', param.QCh);
fprintf(fid,'constant LUTSize_QCh_to_Qmsg : integer := 2**(LUTInputBits_QCh_to_Qmsg);\n');
fprintf(fid,'type LUTType_QCh_to_Qmsg is array (0 to LUTSize_QCh_to_Qmsg-1) of integer range 0 to 2**%d-1;\n', param.QLLR);
fprintf(fid,'constant LUT_QCh_to_Qmsg : LUTType_QCh_to_Qmsg :=(');
fprintf(fid,'%d,', param.Nq_Cha_2_Nq_Msg_map(1:end-1));
fprintf(fid,'%d);\n\n', param.Nq_Cha_2_Nq_Msg_map(end));

% Convert tree to cell
Qcell = cell(param.maxIter,1);
for iter = 1:param.maxIter
    Qcell{iter} = fliplr(param.QVN{iter}.qtree2qcell(param.QLLR,param.QCh));
end

% Iterate over number of iterations
for iter = 1:param.maxIter
    Q = Qcell{iter};
    % Iterate over tree levels
    for level = 1:size(Q,2)
        for node = 1:size(Q,1)
            if( ~isempty(Q{node,level}) )
                fprintf(fid,'constant LUTInputBitsL%d_N%d_S%d : integer := %d;\n', level-1, node-1, iter-1, sum(Q{node,level}.inres));
                fprintf(fid,'constant LUTSizeL%d_N%d_S%d : integer := 2**(LUTInputBitsL%d_N%d_S%d);\n', level-1, node-1, iter-1, level-1, node-1, iter-1);
                fprintf(fid,'type LUTTypeL%d_N%d_S%d is array (0 to LUTSizeL%d_N%d_S%d-1) of integer range 0 to 2**%d-1;\n', level-1, node-1, iter-1, level-1, node-1, iter-1, log2(double(Q{node,level}.outres)));
                fprintf(fid,'subtype LUTAddrL%d_N%d_S%d is std_logic_vector(0 to LUTInputBitsL%d_N%d_S%d-1);\n', level-1, node-1, iter-1, level-1, node-1, iter-1);
                fprintf(fid,'constant LUTL%d_N%d_S%d : LUTTypeL%d_N%d_S%d := (', level-1, node-1, iter-1, level-1, node-1, iter-1);
                
                % Get look-up table mapping
                lut=Q{node,level}.map;
                
                % Write mapping to file
                if( iter == param.maxIter && level == 1 && node == 1)
                    % Invert decision look-up tree outputs to match BPSK mapping
                    fprintf(fid,'%d,', ~lut(1:end-1));
                    fprintf(fid,'%d);\n\n', ~lut(end));
                else
                    fprintf(fid,'%d,', lut(1:end-1));
                    fprintf(fid,'%d);\n\n', lut(end));
                end
            end
        end
    end
end

%% Check nodes

fprintf(fid,['------ Check Nodes ------ \n' ...
    '-- Check node degree\n' ...
    'constant CNodeDegree : integer := %d;\n' ...
    'constant CNodeDegreeLog : integer := integer(log2(real(CNodeDegree)));\n\n'], param.CNodeDegree);

fprintf(fid,['-- Comparator tree depth\n' ...
    'constant treeDepth : integer := integer(ceil(log2(real(CNodeDegree/2)))) + 1;\n' ...
    'constant noLeaves : integer := 2**treeDepth;\n']);

fprintf(fid, ['-- Internal LLR\n' ...
    'type IntLLRTypeC is array (0 to CNodeDegree-1) of IntLLRSubType;\n\n' ...
    '-- Absolute values of internal LLRs\n' ...
    'subtype IntAbsLLRSubType is std_logic_vector(QLLR-2 downto 0);\n' ...
    'type IntAbsLLRTypeC is array (0 to CNodeDegree-1) of IntAbsLLRSubType;\n\n' ...
    '-- Minimum output type\n' ...
    'type MinType is array (0 to 1) of std_logic_vector(QLLR-2 downto 0);\n\n' ...
    '-- Sorter tree types\n' ...
    'type TreeLevelType is array (0 to noLeaves-1) of IntAbsLLRSubType;\n' ...
    'type TreeType is array (0 to treeDepth-1) of TreeLevelType;\n\n']);

%% Pipeline stages

fprintf(fid,['------ Check node stage ------\n' ...
    '-- Check node stage input signal\n' ...
    'type IntLLRTypeCNStage is array(0 to M-1) of IntLLRTypeC;\n\n']);

fprintf(fid,['------ Variable node stage ------\n' ...
    '-- Variable node stage input signal\n' ...
    'type IntLLRTypeVNStage is array(0 to N-1) of IntLLRTypeV;\n\n']);

fprintf(fid,'function to_std_logic(i : in integer range 0 to 1) return std_logic;\n\n');

fprintf(fid,['end config;\n\n' ...
    'package body config is\n\n' ...
    '  function to_std_logic(i : in integer range 0 to 1) return std_logic is\n' ...
    '  begin\n' ...
    '  if i = 0 then\n' ...
    '      return ''0'';\n' ...
    '  end if;\n' ...
    '  return ''1'';\n' ...
    '  end function;\n\n' ...
    'end config;']);

% Close config file
fclose(fid);