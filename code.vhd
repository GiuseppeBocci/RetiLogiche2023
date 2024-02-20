library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PIPO_register8 is
        port(
            en_i: in std_logic;
            rst_i: in std_logic;
            clk_i: in std_logic;
            show_i: in std_logic;
            word_i: in std_logic_vector(7 downto 0);
            word_o: out std_logic_vector(7 downto 0)
        );
end PIPO_register8;
    
architecture PIPO_register8_arch of PIPO_register8 is
    signal word: std_logic_vector(7 downto 0);
begin
    
    register8 : process(clk_i, rst_i)
    --parte sequenziale
    begin
        if rst_i = '1' then
            word <= "00000000";
        elsif clk_i'event and clk_i = '1' and en_i = '1' then
            word <= word_i;
        end if;
    end process;
    
    show : process(show_i, word)
    --parte combinatoria
    begin
        for i in 0 to 7 loop
            word_o(i) <= word(i) and show_i;
        end loop;
    end process;
    
end PIPO_register8_arch;

-- FINE REGISTRO DI USCITA


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity demux4 is
        port(
            sel : in std_logic_vector(1 downto 0);
            x : in std_logic;
            y : out std_logic_vector(3 downto 0)
        );
end demux4;
    
architecture demux4_arch of demux4 is
begin
    scelta : process(x, sel)
    -- combinatorio
    begin
        y <= "0000"; -- caso di errore (nessun enable => dato non salvato)
        if sel = "00" then
            y(0) <= x;
        elsif sel = "01" then
            y(1) <= x;
        elsif sel = "10" then
            y(2) <= x;
        elsif sel <= "11" then
            y(3) <= x;
        end if;
    end process;
end demux4_arch;

-- FINE DEMUX4


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SIPO_register2 is
        port(
            clk_i: in std_logic;
            rst_i: in std_logic;
            in_i: in std_logic;
            en_i: in std_logic;
            Q_o: out std_logic_vector(1 downto 0)
        );
end SIPO_register2;
    
architecture SIPO_register2_arch of SIPO_register2 is
    signal Q : std_logic_vector(1 downto 0);
begin
    SIPO : process(rst_i, clk_i)
    -- sequenziale
    begin
        if rst_i = '1' then
            Q <= "00";
        elsif clk_i'event and clk_i = '1' and en_i = '1' then
            Q(1) <= Q(0);
            Q(0) <= in_i;
        end if;
        Q_o <= Q;
    end process;
end SIPO_register2_arch;

-- FINE SIPO_register2


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SIPO_register16 is
        port(
            clk_i: in std_logic;
            rst_i: in std_logic;
            in_i: in std_logic;
            en_i: in std_logic;
            Q_o: out std_logic_vector(15 downto 0)
        );
end SIPO_register16;
    
architecture SIPO_register16_arch of SIPO_register16 is
    signal Q : std_logic_vector(15 downto 0);
begin
    SIPO : process(rst_i, clk_i)
    -- sequenziale
    begin
        if rst_i = '1' then
            Q <= "0000000000000000";
        elsif clk_i'event and clk_i = '1' and en_i = '1' then
            Q(15 downto 1) <= Q(14 downto 0);
            Q(0) <= in_i;
        end if;
        Q_o <= Q;
    end process;
end SIPO_register16_arch;

-- FINE SIPO_register16

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_w : in std_logic;
        o_z0 : out std_logic_vector(7 downto 0);
        o_z1 : out std_logic_vector(7 downto 0);
        o_z2 : out std_logic_vector(7 downto 0);
        o_z3 : out std_logic_vector(7 downto 0);
        o_done : out std_logic;
        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in std_logic_vector(7 downto 0);
        o_mem_we : out std_logic;
        o_mem_en : out std_logic
    );
end project_reti_logiche;

architecture project_reti_logiche_arch of project_reti_logiche is

    --FSM
    type S is (READ_CH_WAIT, READ_CH_2, READ_ADD, READ_MEM, SHOW);
    signal curr_state: S;
    signal done : std_logic;
    signal save : std_logic;
    signal en_c : std_logic;
    signal en_a_s : std_logic;
    
    signal cls : std_logic;

    --Z registers
    signal z_vector : std_logic_vector(31 downto 0);
    component PIPO_register8 is
        port(
            en_i: in std_logic;
            rst_i: in std_logic;
            clk_i: in std_logic;
            show_i: in std_logic;
            word_i: in std_logic_vector(7 downto 0);
            word_o: out std_logic_vector(7 downto 0)
        );
     end component;
     
     --CHANNEL REGISTER
     signal s_channel : std_logic_vector(1 downto 0);
     component SIPO_register2 is
        port(
            clk_i: in std_logic;
            rst_i: in std_logic;
            in_i: in std_logic;
            en_i: in std_logic;
            Q_o: out std_logic_vector(1 downto 0)
        );
     end component;
     
     --DEMUX 1:4
     signal enables_Z : std_logic_vector(3 downto 0);
     component demux4 is
        port(
            sel : in std_logic_vector(1 downto 0);
            x : in std_logic;
            y : out std_logic_vector(3 downto 0)
        );
     end component;
     
     --ADDRESS REGISTER
     signal en_a : std_logic;
     component SIPO_register16 is
        port(
            clk_i: in std_logic;
            rst_i: in std_logic;
            in_i: in std_logic;
            en_i: in std_logic;
            Q_o: out std_logic_vector(15 downto 0)
        );
    end component;    
    
begin
    --rete combinatoria
    cls <= i_rst or done;
    o_mem_we <= '0';
    o_done <= done;
    en_a <= en_a_s and i_start;
    
    channel_register : SIPO_register2 port map(
            clk_i => i_clk,
            rst_i => cls, 
            in_i => i_w,
            en_i => en_c,
            Q_o => s_channel
        );
        
    address_register : SIPO_register16 port map(
            clk_i => i_clk,
            rst_i => cls,
            in_i => i_w,
            en_i => en_a,
            Q_o => o_mem_addr
        );
    
    dmux4 : demux4 port map(
            sel => s_channel,
            x => save,
            y => enables_Z
    );
    
    genZ: for i in 0 to 3 generate
		Z_regiters: PIPO_register8 port map(
            en_i => enables_Z(i),
            rst_i => i_rst,
            clk_i => i_clk,
            show_i => done,
            word_i => i_mem_data,
            word_o => z_vector(((i+1)*8 - 1) downto i*8)
        );
	end generate;
	
	--"Circuito" combonatorio output
	o_z0 <= z_vector(7 downto 0);
	o_z1 <= z_vector(15 downto 8);
	o_z2 <= z_vector(23 downto 16);
	o_z3 <= z_vector(31 downto 24);
	
	--FSM
	FSM_delta : process(i_clk, i_rst)
	begin
	   if i_rst = '1' then
	       curr_state <= READ_CH_WAIT;
	   elsif i_clk'event and i_clk = '1' then
	       if curr_state = READ_CH_WAIT and i_start = '1' then --and i_start = '1' perché è anche stato di wait
               curr_state <= READ_CH_2;
           elsif curr_state = READ_CH_2 then
               curr_state <= READ_ADD;
           elsif curr_state = READ_ADD and i_start = '0' then
               curr_state <= READ_MEM;
           elsif curr_state = READ_MEM then
               curr_state <= SHOW;
           elsif curr_state = SHOW then
               curr_state <= READ_CH_WAIT;
           end if;
	   end if;
	end process;
	
	FSM_lambda : process(curr_state)
	begin
       o_mem_en <= '0';
       done <= '0';
       en_a_s <= '0';
       en_c <= '0';
       save <= '0';
	   if curr_state = READ_CH_WAIT then
	       en_c <= '1';
	   elsif curr_state = READ_CH_2 then
	       en_c <= '1';
	   elsif curr_state = READ_ADD then
	       en_a_s <= '1';
	       o_mem_en <= '1';
	       --save <= '1'; -- indifferente
	   elsif curr_state = READ_MEM then
	       save <= '1';
	       --o_mem_en <= '1'; --indifferente
       elsif curr_state = SHOW then
	       done <= '1';
	   end if;
	end process;

end project_reti_logiche_arch;
