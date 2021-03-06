library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
library work;
use work.config.all;


entity VNStage is
  port (
    ClkxCI            : in std_logic;
    RstxRBI           : in std_logic;
    IntLLRVNStagexDI  : in IntLLRTypeVNStage;  -- A 3-D array of M times CNdegree time  Q bit width
    ChLLRVNStagexDI   : in ChLLRTypeStage;  -- A 2-D array of N times Q bit width
		IntLLRVNStagexDO  : out IntLLRTypeVNStage;
		ChLLRVNStagexDO   : out ChLLRTypeStage
    );
    
end VNStage;

architecture structural of VNStage is
	
  component VNodeAdders is  
    port (
      ChLLRInxDI   : in  ChLLRType;
      CVLLRInxDI   : in  IntLLRTypeV;
      VCLLROutxDO  : out IntLLRTypeV);
  end component;

  -- Register bank to store channel LLRs
  component ChLLRRegBank
  port (
    ClkxCI           : in std_logic;
    RstxRBI          : in std_logic;   
    ChLLRxDI         : in ChLLRTypeStage;  -- A 2-D array of N times Q bit width
    ChLLRxDO         : out ChLLRTypeStage
    );    
  end component;

  -- Register bank to store internal LLRs
  component IntLLRVNStageRegBank
  port (
    ClkxCI           : in std_logic;
    RstxRBI          : in std_logic;   
    IntLLRVNStagexDI : in IntLLRTypeVNStage;
    IntLLRVNStagexDO : out IntLLRTypeVNStage
    );    
  end component;

  signal IntLLRVNStagexD : IntLLRTypeVNStage;
    
begin  -- structural

-- Instantiate register banks
  -- Channel LLRs
  ChLLRRegBank_1: ChLLRRegBank port map (
    ClkxCI => ClkxCI,
    RstxRBI => RstxRBI,
    ChLLRxDI => ChLLRVNStagexDI,
    ChLLRxDO => ChLLRVNStagexDO
  );

  -- Internal messages
  IntLLRVNStageRegBank_1: IntLLRVNStageRegBank port map (
    ClkxCI => ClkxCI,
    RstxRBI => RstxRBI,
    IntLLRVNStagexDI => IntLLRVNStagexD,
    IntLLRVNStagexDO => IntLLRVNStagexDO
  );

  Gen_VariableNode: for i in 0 to N-1 generate
     VNode_Inst : VNodeAdders port map (
			 ChLLRInxDI => ChLLRVNStagexDI(i),
       CVLLRInxDI => IntLLRVNStagexDI(i),
       VCLLROutxDO => IntLLRVNStagexD(i));
  end generate;


  
end structural;
