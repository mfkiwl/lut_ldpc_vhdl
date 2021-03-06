library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.config.all;

entity VNodeAdders is
  
  port (
    ChLLRInxDI   : in  ChLLRType;
    CVLLRInxDI   : in  IntLLRTypeV;
    VCLLROutxDO  : out IntLLRTypeV
    );
end VNodeAdders;

architecture arch of VNodeAdders is

signal ExtendedInputsxD : ExtendedInputType;
signal ExtendedOutputsxD : ExtendeDInputType;
  
signal AdderTreexD : VNodeTreeType;

begin  -- arch

  -- Zero-pad inputs
  extendInputs: process (CVLLRInxDI)
  begin  -- process adderTree

    -- Default assignment
    ExtendedInputsxD <= (others=>(others=>'0'));

    -- Assign inputs
    for ii in 0 to VNodeDegree-1 loop
      ExtendedInputsxD(ii)(QLLR-1 downto 0) <= CVLLRInxDI(ii)(QLLR-1 downto 0);
    end loop;  -- ii
    ExtendedInputsxD(VNodenoLeaves-1)(QLLR-1 downto 0) <= ChLLRInxDI(QLLR-1 downto 0);
    
  end process extendInputs;
  
  -- Add all inputs in an adder tree
  adderTree: process (ChLLRinxDI, ExtendedInputsxD)
  begin  -- process adderTree

    -- Default assignment
    AdderTreexD <= (others=>(others=>(others=>'0')));
    -- Assign inputs
    for ii in 0 to VNodenoLeaves-1 loop
      AdderTreexD(0)(ii) <= ExtendedInputsxD(ii);
    end loop;  -- ii

    -- Process remaining levels of tree
    for ii in 1 to VNodetreeDepth-1 loop
      for jj in 0 to 2**(VNodetreeDepth-ii-1)-1 loop
        AdderTreexD(ii)(jj) <= AdderTreexD(ii-1)(2*jj) + AdderTreexD(ii-1)(2*jj+1);
      end loop;  -- jj      
      
    end loop;  -- ii
    
  end process adderTree;

  -- Compute output LLRs
  getOutputs: process (AdderTreexD,ExtendedInputsxD)
  begin  -- process getOutputs
    
     -- AdderTreexD(VNodetreeDepth-1)(0) contains sum of all inputs
     for ii in 0 to VNodeDegree-1 loop
       ExtendedOutputsxD(ii) <= AdderTreexD(VNodetreeDepth-1)(0) - ExtendedInputsxD(ii);
     end loop;  -- ii

     -- Saturate if needed
     for ii in 0 to VNodeDegree-1 loop
       if( ExtendedOutputsxD(ii)(QLLR) = '0' ) then
         VCLLROutxDO(ii)(QLLR-1 downto 0) <= ExtendedOutputsxD(ii)(QLLR-1 downto 0);
       else
         VCLLROutxDO(ii)(QLLR-1) <= '1';
         VCLLROutxDO(ii)(QLLR-2 downto 0) <= ExtendedOutputsxD(ii)(QLLR-2 downto 0);
       end if;
     end loop;  -- ii
  end process getOutputs;
 
  
end arch;
