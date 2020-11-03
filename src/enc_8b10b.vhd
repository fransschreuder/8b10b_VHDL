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
 
entity enc_8b10b is     
    port( 
        reset : in std_logic;          -- Active high reset
        clk : in std_logic ;           -- Clock to register dataout
        ena : in std_logic ;           -- To validate datain and register dataout and disparity
        KI : in std_logic ;            -- Control (K) input(active high) 
        datain : in std_logic_vector(7 downto 0); --8 bit input data
        dataout : out std_logic_vector(9 downto 0) --10 bit encoded output
        ); 
end enc_8b10b; 
 
architecture behavioral of enc_8b10b is 
 
    signal aeqb : std_logic; -- (ai & bi) | (!ai & !bi) ;
    signal ceqd : std_logic; -- (ci & di) | (!ci & !di) ;
    signal l22 : std_logic; -- (ai & bi & !ci & !di) |
    signal l40 : std_logic; -- ai & bi & ci & di ;
    signal l04 : std_logic; -- !ai & !bi & !ci & !di ;
    signal l13 : std_logic; -- ( !aeqb & !ci & !di) |
    signal l31 : std_logic; -- ( !aeqb & ci & di) |
    signal pd1s6 : std_logic; -- (ei & di & !ci & !bi & !ai) | (!ei & !l22 & !l31) ;
    signal nd1s6 : std_logic; -- ki | (ei & !l22 & !l13) | (!ei & !di & ci & bi & ai) ;
    signal ndos6 : std_logic; -- pd1s6 ;
    signal pdos6 : std_logic; -- ki | (ei & !l22 & !l13) ;
    signal alt7 : std_logic; -- fi & gi & hi & (ki | 
    signal nd1s4 : std_logic; -- fi & gi ;
    signal pd1s4 : std_logic; -- (!fi & !gi) | (ki & ((fi & !gi) | (!fi & gi))) ;
    signal ndos4 : std_logic; -- (!fi & !gi) ;
    signal pdos4 : std_logic; -- fi & gi & hi ;
    --signal illegalk : std_logic; -- ki & 
    signal compls6 : std_logic; -- (pd1s6 & !dispin) | (nd1s6 & dispin) ;
    signal disp6 : std_logic; -- dispin ^ (ndos6 | pdos6) ;
    signal compls4 : std_logic; -- (pd1s4 & !disp6) | (nd1s4 & disp6) ;
    signal ai : std_logic;
    signal bi : std_logic;
    signal ci : std_logic;
    signal di : std_logic;
    signal ei : std_logic;
    signal fi : std_logic;
    signal gi : std_logic;
    signal hi : std_logic;
    signal ao : std_logic;
    signal bo : std_logic;
    signal co : std_logic;
    signal do : std_logic;
    signal eo : std_logic;
    signal io : std_logic;
    signal fo : std_logic;
    signal go : std_logic;
    signal ho : std_logic;
    signal jo : std_logic;
    signal dispin, dispout: std_logic;
begin 

    ai <= datain(0) ;
    bi <= datain(1) ;
    ci <= datain(2) ;
    di <= datain(3) ;
    ei <= datain(4) ;
    fi <= datain(5) ;
    gi <= datain(6) ;
    hi <= datain(7) ;

    disp_proc: process(clk, reset)
    begin
        if reset = '1' then
            dispin <= '0';
            dataout <= "0000000000";
        elsif rising_edge(clk) then
            if ena = '1' then
             dispin <= dispout;
             dataout <=  (ao  xor  compls6)&(bo  xor  compls6)&
                (co  xor  compls6)&(do  xor  compls6)&
                (eo  xor  compls6)&(io  xor  compls6)&              
                (fo  xor  compls4)&(go  xor  compls4)&
                (ho  xor  compls4)&(jo  xor  compls4);
            end if;
        end if;
        
    end process;

    aeqb <= (ai  and  bi)  or  (not ai  and  not bi) ;
    ceqd <= (ci  and  di)  or  (not ci  and  not di) ;
    l22 <= (ai  and  bi  and  not ci  and  not di)  or 
          (ci  and  di  and  not ai  and  not bi)  or 
          ( not aeqb  and  not ceqd) ;
    l40 <= ai  and  bi  and  ci  and  di ;
    l04 <= not ai  and  not bi  and  not ci  and  not di ;
    l13 <= ( not aeqb  and  not ci  and  not di)  or 
          ( not ceqd  and  not ai  and  not bi) ;
    l31 <= ( not aeqb  and  ci  and  di)  or 
         ( not ceqd  and  ai  and  bi) ;

    -- The 5B/6B encoding

    ao <= ai ;
    bo <= (bi  and  not l40)  or  l04 ;
    co <= l04  or  ci  or  (ei  and  di  and  not ci  and  not bi  and  not ai) ;
    do <= di  and  (not  (ai  and  bi  and  ci)) ;
    eo <= (ei  or  l13)  and  not  (ei  and  di  and  not ci  and  not bi  and  not ai) ;
    io <= (l22  and  not ei)  or 
        (ei  and  not di  and  not ci  and  not (ai and bi))  or   -- D16, D17, D18
        (ei  and  l40)  or 
        (KI  and  ei  and  di  and  ci  and  not bi  and  not ai)  or  -- K.28
        (ei  and  not di  and  ci  and  not bi  and  not ai) ;

    -- pds16 indicates cases where d-1 is assumed + to get our encoded value
    pd1s6 <= (ei  and  di  and  not ci  and  not bi  and  not ai)  or  (not ei  and  not l22  and  not l31) ;
    -- nds16 indicates cases where d-1 is assumed - to get our encoded value
    nd1s6 <= KI  or  (ei  and  not l22  and  not l13)  or  (not ei  and  not di  and  ci  and  bi  and  ai) ;

    -- ndos6 is pds16 cases where d-1 is + yields - disp out - all of them
    ndos6 <= pd1s6 ;
    -- pdos6 is nds16 cases where d-1 is - yields + disp out - all but one
    pdos6 <= KI  or  (ei  and  not l22  and  not l13) ;


    -- some Dx.7 and all Kx.7 cases result in run length of 5 case unless
    -- an alternate coding is used (referred to as Dx.A7, normal is Dx.P7)
    -- specifically, D11, D13, D14, D17, D18, D19.
    alt7_proc: process(fi, gi, hi, KI, ei, dispin, di, l31, l13)
        variable dispval : std_logic;
    begin
        if dispin = '1' then
            dispval := (not ei and di and l31);
        else
            dispval := (ei and not di and l13);
        end if;
        alt7 <= fi and gi and hi and (KI or dispval);
    end process;
      

   
    fo <= fi  and  not  alt7 ;
    go <= gi  or  (not fi  and  not gi  and  not hi) ;
    ho <= hi ;
    jo <= (not hi  and  (gi  xor  fi))  or  alt7 ;

    -- nd1s4 is cases where d-1 is assumed - to get our encoded value
    nd1s4 <= fi  and  gi ;
    -- pd1s4 is cases where d-1 is assumed + to get our encoded value
    pd1s4 <= (not fi  and  not gi)  or  (KI  and  ((fi  and  not gi)  or  (not fi  and  gi))) ;

    -- ndos4 is pd1s4 cases where d-1 is + yields - disp out - just some
    ndos4 <= (not fi  and  not gi) ;
    -- pdos4 is nd1s4 cases where d-1 is - yields + disp out 
    pdos4 <= fi  and  gi  and  hi ;

    -- only legal K codes are K28.0->.7, K23/27/29/30.7
    --    K28.0->7 is ei<=di<=ci<=1,bi<=ai<=0
    --    K23 is 10111
    --    K27 is 11011
    --    K29 is 11101
    --    K30 is 11110 - so K23/27/29/30 are ei  and  l31
    --illegalk <= KI  and  
          --(ai  or  bi  or  not ci  or  not di  or  not ei)  and  -- not K28.0->7
          --(not fi  or  not gi  or  not hi  or  not ei  or  not l31) ; -- not K23/27/29/30.7

    -- now determine whether to do the complementing
    -- complement if prev disp is - and pd1s6 is set, or + and nd1s6 is set
    compls6 <= (pd1s6  and  (not dispin))  or  (nd1s6  and  dispin) ;

    -- disparity out of 5b6b is disp in with pdso6 and ndso6
    -- pds16 indicates cases where d-1 is assumed + to get our encoded value
    -- ndos6 is cases where d-1 is + yields - disp out
    -- nds16 indicates cases where d-1 is assumed - to get our encoded value
    -- pdos6 is cases where d-1 is - yields + disp out
    -- disp toggles in all ndis16 cases, and all but that 1 nds16 case

    disp6 <= dispin  xor  (ndos6  or  pdos6) ;

    compls4 <= (pd1s4  and  not disp6)  or  (nd1s4  and  disp6) ;
    dispout <= disp6  xor  (ndos4  or  pdos4) ;


                          
                 
end behavioral; 
