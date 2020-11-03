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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.numeric_std_unsigned.all;
library uvvm_util;
context uvvm_util.uvvm_util_context;
use std.env.all;

use work.lookup_8b10b.all; --code8b10b lookup table
entity validate_8b10b_tb is
end entity validate_8b10b_tb;

architecture test of validate_8b10b_tb is
    signal encodein, encodein_p1, encodein_p2, encodein_p3: std_logic_vector(8 downto 0);
    signal i: integer := 0;
    signal encodeout, encodeout_vr, encodeout_vrev : std_logic_vector(9 downto 0) := (others => '0');
    signal encodeout_v : std_logic_vector(0 to 9) := (others => '0');
    signal decodein_v : std_logic_vector(0 to 9) := (others => '0');
    signal decodeerr, disperr : std_logic := '0';
    signal decodeerr_v, disperr_v : std_logic := '0';
    signal decodeerr_vr, disperr_vr : std_logic := '0';
    signal enc_dispin, enc_dispout : std_logic := '0';
    signal dec_dispin, dec_dispout : std_logic := '0';
    signal decodeout, decodeout_v, decodeout_vr : std_logic_vector(8 downto 0) := (others => '0');
    
    signal code: code_type;
    
    signal legal: std_logic_vector(1023 downto 0);  -- mark every used 10b symbol as legal, leave rest marked as not
    signal okdisp: std_logic_vector(2047 downto 0); -- now mark every used combination of symbol and starting disparity
    signal mapcode: slv9_array(1023 downto 0) ;
    signal decodein : std_logic_vector(9 downto 0) := (others => '0');
    
    signal clk, reset: std_logic := '1';
    constant clk_period: time := 10 ns;
  -- Interrupt related signals
  signal clock_ena     : boolean   := false;

begin
  
        -----------------------------------------------------------------------------
    -- Clock Generator
    -----------------------------------------------------------------------------
    clock_generator(clk, clock_ena, clk_period, "100 MHz clock");
    
    reset_proc: process
    begin
        reset <= '1';
        wait for clk_period;
        reset <= '0';
        wait;
    end process;
    

    DUTE: entity work.enc_8b10b port map(
        reset => reset,
        clk => clk,
        ena => '1',
        KI => code.k,
        datain => code.val_8b,
        dataout => encodeout
    );
    


    
    DUTD: entity work.dec_8b10b port map(
        reset => reset,
        clk => clk,
        datain => decodein,
        ena => '1',
        ko => decodeout(8),
        dataout => decodeout(7 downto 0),
        code_err => decodeerr,
        disp_err => disperr
    );
    


    
    pipe_proc: process(clk, reset)
    begin
        if reset = '1' then
            encodein_p1 <= (others => '0');
            encodein_p2 <= (others => '0');
            encodein_p3 <= (others => '0');
        elsif rising_edge(clk) then
            encodein_p1 <= code.k&code.val_8b;
            encodein_p2 <= encodein_p1;
            encodein_p3 <= encodein_p2;
        end if;
    end process;
    
    selectCode: process(i)
    begin
        if i < 268 then
            code <= code8b10b(i);
        else
            code <= ('U', "UUUUUUUU", "UUUUUUUUUU", "UUUUUUUUUU", 'U');
        end if;
    end process;
    
    sequencer: process
        variable last_encodein: std_logic_vector(8 downto 0);
    begin
        report_global_ctrl(VOID);
        report_msg_id_panel(VOID);
        enable_log_msg(ALL_MESSAGES);
        clock_ena <= true;
        wait until reset = '0';
        log(ID_SEQUENCER, "\n\nFirst, test by trying all 268 (256 Dx.y and 12 Kx.y)", C_SCOPE);
        log(ID_SEQUENCER, "valid inputs, with both + and - starting disparity.", C_SCOPE);
        log(ID_SEQUENCER, "We check that the encoder output and ending disparity is correct.", C_SCOPE);
        log(ID_SEQUENCER, "We also check that the decoder matches.", C_SCOPE);

        for il in 0 to 267 loop
            i <= il;
            wait_num_rising_edge(clk, 1);
            decodein <= encodeout ;
            wait_num_rising_edge(clk, 1);
            check_value((((encodeout /= code.val_10b_neg) and (encodeout /= code.val_10b_pos))), false, ERROR,  "Check encoding", C_SCOPE);
            decodein <= encodeout ;
            wait_num_rising_edge(clk, 1);
            decodein <= encodeout ;
            check_value(encodein_p3(8 downto 0), decodeout(8 downto 0), ERROR, "Encoder input should match decoder output", C_SCOPE);
            check_value(decodeerr, '0', ERROR, "Check decode error", C_SCOPE);
            check_value(disperr, '0', ERROR, "Check disparity error", C_SCOPE);
        end loop;

        -- Now, having verified all legal codes, lets run some illegal codes
        -- at the decoder... how to figure illegal codes ?  2048 possible cases,
        -- lets mark the OK ones...
        legal <= (others => '0');
        okdisp <= (others => '0');
        for il in 0 to 267 loop
            i <= il;
            wait_num_rising_edge(clk, 1);
            legal(to_integer(unsigned(code.val_10b_neg))) <= '1' ;
            legal(to_integer(unsigned(code.val_10b_pos))) <= '1' ;
            mapcode(to_integer(unsigned(code.val_10b_neg))) <= code.k&code.val_8b;
            mapcode(to_integer(unsigned(code.val_10b_pos))) <= code.k&code.val_8b;
        end loop;

        log(ID_SEQUENCER, "Now lets test all (legal and illegal) codes into the decoder.", C_SCOPE);
        log(ID_SEQUENCER, "checking all possible decode inputs", C_SCOPE) ;
        for il in 0 to 1023 loop
            i <= il;
            wait_num_rising_edge(clk, 1);
            decodein <= std_logic_vector(to_unsigned(i,10));
            wait_num_rising_edge(clk, 1);
            wait_num_rising_edge(clk, 1);
            check_value(((legal(i) = '0')  and  (decodeerr /= '1')), false, WARNING, "Detection of illegal code", C_SCOPE);
            check_value((legal(i) = '1'  and  (mapcode(i) /= decodeout)), false, ERROR, "Check decoder output", C_SCOPE) ;
            wait_num_rising_edge(clk, 1);
        end loop;
        report_alert_counters(FINAL); -- Report final counters and print conclusion for simulation (Success/Fail)
        log(ID_SEQUENCER, "SIMULATION COMPLETED", C_SCOPE);
        std.env.stop;
        wait;
    end process;
   
end test;
