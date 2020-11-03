-- Copyright 2002    Chuck Benz, Hollis, NH   
-- Copyright 2020    Frans Schreuder
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.


-- The information and description contained herein is the
-- property of Chuck Benz.
--
-- Permission is granted for any reuse of this information
-- and description as long as this copyright notice is
-- preserved.  Modifications may be made as long as this
-- notice is preserved.

-- Changelog:
-- 11 October  2002: Chuck Benz: updated with clearer messages, and checking decodeout
-- 3  November 2020: Frans Schreuder: Translated to VHDL, added UVVM testbench
--                                    Original verilog code: http://asics.chuckbenz.com/#My_open_source_8b10b_encoderdecoder
--
-- per Widmer and Franaszek


library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
 
entity dec_8b10b is	 
    port( 
        reset : in std_logic; --Active high reset
        clk : in std_logic;   --Clock to register output and disparity
        datain : in std_logic_vector(9 downto 0); --10b data input
        ena : in std_logic;              -- Enable registers for output and disparity
        ko : out std_logic ;             -- Active high K indication
        dataout : out std_logic_vector(7 downto 0); --Decoded output
        code_err : out std_logic;                   --Indication for illegal character
        disp_err : out std_logic                    --Indication for disparity error
    ); 
end dec_8b10b; 

architecture behavioral of dec_8b10b is

    signal dispin      : std_logic;
    signal dispout     : std_logic;
    signal ai          : std_logic;
    signal bi          : std_logic;
    signal ci          : std_logic;
    signal di          : std_logic;
    signal ei          : std_logic;
    signal ii          : std_logic;
    signal fi          : std_logic;
    signal gi          : std_logic;
    signal hi          : std_logic;
    signal ji          : std_logic;
    signal aeqb        : std_logic;
    signal ceqd        : std_logic;
    signal p22         : std_logic;
    signal p13         : std_logic;
    signal p31         : std_logic;
    signal disp6a      : std_logic;
    signal disp6a2     : std_logic;
    signal disp6a0     : std_logic;
    signal disp6b      : std_logic;
    signal p22bceeqi   : std_logic;
    signal p22bncneeqi : std_logic;
    signal p13in       : std_logic;
    signal p31i        : std_logic;
    signal p13dei      : std_logic;
    signal p22aceeqi   : std_logic;
    signal p22ancneeqi : std_logic;
    signal p13en       : std_logic;
    signal anbnenin    : std_logic;
    signal abei        : std_logic;
    signal cndnenin    : std_logic;
    signal compa       : std_logic;
    signal compb       : std_logic;
    signal compc       : std_logic;
    signal compd       : std_logic;
    signal compe       : std_logic;
    signal ao          : std_logic;
    signal bo          : std_logic;
    signal co          : std_logic;
    signal do          : std_logic;
    signal eo          : std_logic;
    signal feqg        : std_logic;
    signal heqj        : std_logic;
    signal fghj22      : std_logic;
    signal fghjp13     : std_logic;
    signal fghjp31     : std_logic;
    signal ko_s        : std_logic;
    signal k28p        : std_logic;
    signal fo          : std_logic;
    signal go          : std_logic;
    signal ho          : std_logic;
    signal disp6p      : std_logic;
    signal disp6n      : std_logic;
    signal disp4p      : std_logic;
    signal disp4n      : std_logic;

  
begin

    ai <= datain(9);
    bi <= datain(8);
    ci <= datain(7);
    di <= datain(6);
    ei <= datain(5);
    ii <= datain(4);
    fi <= datain(3);
    gi <= datain(2);
    hi <= datain(1);
    ji <= datain(0);

    aeqb <= (ai and bi) or (not ai and not bi) ;
    ceqd <= (ci and di) or (not ci and not di) ;
    p22 <= (ai and bi and not ci and not di) or
          (ci and di and not ai and not bi) or
          ( not aeqb and not ceqd) ;
    p13 <= ( not aeqb and not ci and not di) or
          ( not ceqd and not ai and not bi) ;
    p31 <= ( not aeqb and ci and di) or
          ( not ceqd and ai and bi) ;


    disp6a <= p31 or (p22 and dispin) ; -- pos disp if p22 and was pos, or p31.
    disp6a2 <= p31 and dispin ;  -- disp is ++ after 4 bits
    disp6a0 <= p13 and not  dispin ; -- -- disp after 4 bits
    
    disp6b <= (((ei and ii and not  disp6a0) or (disp6a and (ei or ii)) or disp6a2 or
             (ei and ii and di)) and (ei or ii or di)) ;

  -- The 5B/6B decoding special cases where ABCDE not <= abcde

    p22bceeqi <= p22 and bi and ci and (not (ei xor ii));
    p22bncneeqi <= p22 and not bi and not ci and (not (ei xor ii));
    p13in <= p13 and not ii ;
    p31i <= p31 and ii ;
    p13dei <= p13 and di and ei and ii ;
    p22aceeqi <= p22 and ai and ci and (not (ei xor ii)) ;
    p22ancneeqi <= p22 and not ai and not ci and (not (ei xor ii));
    p13en <= p13 and not ei ;
    anbnenin <= not ai and not bi and not ei and not ii ;
    abei <= ai and bi and ei and ii ;
    cndnenin <= not ci and not di and not ei and not ii ;

    compa <= p22bncneeqi or p31i or p13dei or p22ancneeqi or 
            p13en or abei or cndnenin ;
    compb <= p22bceeqi or p31i or p13dei or p22aceeqi or 
            p13en or abei or cndnenin ;
    compc <= p22bceeqi or p31i or p13dei or p22ancneeqi or 
            p13en or anbnenin or cndnenin ;
    compd <= p22bncneeqi or p31i or p13dei or p22aceeqi or
            p13en or abei or cndnenin ;
    compe <= p22bncneeqi or p13in or p13dei or p22ancneeqi or 
            p13en or anbnenin or cndnenin ;

    ao <= ai xor compa ;
    bo <= bi xor compb ;
    co <= ci xor compc ;
    do <= di xor compd ;
    eo <= ei xor compe ;

    feqg <= (fi and gi) or (not fi and not gi) ;
    heqj <= (hi and ji) or (not hi and not ji) ;
    fghj22 <= (fi and gi and not hi and not ji) or
             (not fi and not gi and hi and ji) or
             ( not feqg and not heqj) ;
    fghjp13 <= ( not feqg and not hi and not ji) or
              ( not heqj and not fi and not gi) ;
    fghjp31 <= ( (not feqg) and hi and ji) or
              ( not heqj and fi and gi) ;

    dispout <= (fghjp31 or (disp6b and fghj22) or (hi and ji)) and (hi or ji) ;

    ko_s <= ( (ci and di and ei and ii) or ( not ci and not di and not ei and not ii) or
         (p13 and not ei and ii and gi and hi and ji) or
         (p31 and ei and not ii and not gi and not hi and not ji)) ;

    -- k28 with positive disp into fghi - .1, .2, .5, and .6 special cases
    k28p <= not  (ci or di or ei or ii) ;
    fo <= (ji and not fi and (hi or not gi or k28p)) or
         (fi and not ji and (not hi or gi or not k28p)) or
         (k28p and gi and hi) or
         (not k28p and not gi and not hi) ;
    go <= (ji and not fi and (hi or not gi or not k28p)) or
         (fi and not ji and (not hi or gi or k28p)) or
         (not k28p and gi and hi) or
         (k28p and not gi and not hi) ;
    ho <= ((ji xor hi) and not  ((not fi and gi and not hi and ji and not k28p) or (not fi and gi and hi and not ji and k28p) or 
         (fi and not gi and not hi and ji and not k28p) or (fi and not gi and hi and not ji and k28p))) or
         (not fi and gi and hi and ji) or (fi and not gi and not hi and not ji) ;

    disp6p <= (p31 and (ei or ii)) or (p22 and ei and ii) ;
    disp6n <= (p13 and not  (ei and ii)) or (p22 and not ei and not ii) ;
    disp4p <= fghjp31 ;
    disp4n <= fghjp13 ;


    output_proc: process(clk, reset)
    begin
        if reset = '1' then
            dispin <= '0';
            disp_err <= '0';
            dataout <= x"00";
            ko <= '0';
            code_err <= '0';
        elsif rising_edge(clk) then
            if ena = '1' then
                --Rewritten code_err calculation after reading A DC-Balanced, Partitioned-Block, 8B/ 1 OB Transmission Code (A. X. Widmer and P. A. Franaszek)
                code_err <= ((ai and bi and ci and di) or (not (ai or bi or ci or di))) or
                            (p13 and (not ei) and (not ii)) or
                            (p31 and ei and ii) or
                            ((fi and gi and hi and ji) or (not (fi or gi or hi or ji))) or
                            ((ei and ii and fi and gi and hi) or (not (ei or ii or fi or gi or hi))) or
                            (((not ii) and  ei and gi and hi and ji) or (not ((not ii) or  ei or gi or hi or ji))) or
                            ((((not ei) and (not ii) and gi and hi and ji) or (not ((not ei) or (not ii) or gi or hi or ji))) and
                            (not ((ci and di and ei) or (not (ci or di or ei))))) or
                            ((not p31) and ei and (not ii) and (not gi) and (not hi) and (not ji)) or
                            ((not p13) and (not ei) and ii and gi and hi and ji);
                            

                disp_err <= ((dispin and disp6p) or (disp6n and not dispin) or
                             (dispin and not disp6n and fi and gi) or
                             (dispin and ai and bi and ci) or
                             (dispin and not disp6n and disp4p) or
                             (not dispin and not disp6p and not fi and not gi) or
                             (not dispin and not ai and not bi and not ci) or
                             (not dispin and not disp6p and disp4n) or
                             (disp6p and disp4p) or (disp6n and disp4n)) ;
                dispin <= dispout;
                dataout <= ho & go & fo & eo & do & co & bo & ao;
                ko <= ko_s;
            end if;
        end if;
    end process;
  
end architecture behavioral;
