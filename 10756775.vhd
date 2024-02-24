library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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

architecture Behavioral of project_reti_logiche is
    signal first_bit_curr: std_logic := '0'; -- memorizzo il primo bit di intestazione
    signal first_bit_next: std_logic := '0'; 
    signal second_bit_curr: std_logic := '0';-- memorizzo il secondo bit di intestazione
    signal second_bit_next: std_logic := '0'; 
    
    signal mem_add_curr: std_logic_vector(15 downto 0) := "0000000000000000"; -- memorizzo gli N bit (indirizzo di memoria)
    signal mem_add_next: std_logic_vector(15 downto 0) := "0000000000000000";
    
    signal mem_z0_curr: std_logic_vector(7 downto 0) := "00000000"; -- segnale di z0 corrente
    signal mem_z1_curr: std_logic_vector(7 downto 0) := "00000000";
    signal mem_z2_curr: std_logic_vector(7 downto 0) := "00000000";
    signal mem_z3_curr: std_logic_vector(7 downto 0) := "00000000";
    
    signal mem_z0_next: std_logic_vector(7 downto 0) := "00000000"; -- segnale che memorizza z0 
    signal mem_z1_next: std_logic_vector(7 downto 0) := "00000000";
    signal mem_z2_next: std_logic_vector(7 downto 0) := "00000000";
    signal mem_z3_next: std_logic_vector(7 downto 0) := "00000000";
    
    signal i_w_reg: std_logic := '0'; -- segnale che memorizza il valore il bit in ingresso
    
    type state is (RESET, S0, S1, S2, S3, S4, S5, S6, S7);
    signal curr_state : state := S0; -- inizializzo lo stato corrente allo stato di reset 
    signal next_state: state := S0; 
    
begin
    process(i_clk, i_rst)
    begin
        if i_rst='1' then   -- reset asincrono
            curr_state <= RESET;               
            first_bit_curr <= '0';   
            second_bit_curr <= '0';
            mem_z0_curr <= "00000000"; -- azzero memoria uscite
            mem_z1_curr <= "00000000";
            mem_z2_curr <= "00000000";
            mem_z3_curr <= "00000000";
            mem_add_curr <= "0000000000000000";
            i_w_reg <= '0';   
        elsif rising_edge(i_clk) then   
            curr_state <= next_state; -- sul fronte di salita del clock passa allo stato prossimo
            first_bit_curr <= first_bit_next;  -- gestione dei registri 
            second_bit_curr <= second_bit_next;
            mem_z0_curr <= mem_z0_next; 
            mem_z1_curr <= mem_z1_next;
            mem_z2_curr <= mem_z2_next;
            mem_z3_curr <= mem_z3_next;
            mem_add_curr <= mem_add_next;
            i_w_reg <= i_w;                 
        end if;
    end process; 
    
    -- descrizione della funzione di stato prossimo della FSM che dipende dallo stato corrente e dagli ingressi
    process(curr_state, i_start)   
    begin
        next_state <= curr_state; -- assegno valore di default 
        case curr_state is
            when RESET =>  -- STATO DI RESET
                if i_start='1' then
                    next_state <= s1;
                end if;
            when S0 =>  -- STATO DI PARTENZA (no reset)
                if i_start = '1' then
                    next_state <= s1; 
                end if;
            when S1 => -- LETTURA FIRST BIT 
                next_state <= s2;
            when S2 => -- LETTURA SECOND BIT
                if i_start='1' then
                    next_state <= s3;
                elsif i_start<='0' then
                    next_state <= s4;
                end if;  
            when S3 => -- LETTURA SEQUENZA DI N BIT (INDIRIZZO DI MEMORIA)
                if i_start = '1' then
                    next_state <= s3;
                elsif i_start<='0' then
                    next_state <= s4; 
                end if;
            when S4 => -- LETTURA DALLA MEMORIA
                next_state <= s5;
            when S5 => --ATTESA del MESSAGGIO dalla memoria
                next_state <= s6;
            when S6 => -- INDIRIZZAMENTO DEL  MESSAGGIO 
                next_state <= s7; 
            when S7 => -- DONE A 1
                next_state <= s0;
        end case; 
    end process;
    
    -- funzione d'uscita
    process(curr_state, first_bit_curr, second_bit_curr, mem_add_curr, mem_z0_curr, mem_z1_curr, mem_z2_curr, mem_z3_curr,i_w_reg,i_mem_data)
        variable conc: std_logic_vector(15 downto 0); 
        variable temp: std_logic_vector(15 downto 0);
    begin
        first_bit_next <= first_bit_curr;
        second_bit_next <= second_bit_curr;
                
        mem_add_next <= mem_add_curr;
                
        temp := mem_add_curr; 
        
        mem_z0_next <= mem_z0_curr; 
        mem_z1_next <= mem_z1_curr;
        mem_z2_next <= mem_z2_curr;
        mem_z3_next <= mem_z3_curr;
               
        o_mem_we <= '0'; -- NON scrivo in memoria
        o_mem_en <= '0'; -- NON leggo/scrivo in memoria
        o_done <= '0'; -- NON mostro le uscite
        o_z0 <= "00000000";
        o_z1 <= "00000000";
        o_z2 <= "00000000";
        o_z3 <= "00000000";
       
        o_mem_addr <= "0000000000000000"; 

        case curr_state is
            when RESET =>  --stato di RESET 
                o_done <= '0'; -- azzero le uscite
                o_z0 <= "00000000";
                o_z1 <= "00000000";
                o_z2 <= "00000000";
                o_z3 <= "00000000";
                
                mem_z0_next <= "00000000";
                mem_z1_next <= "00000000";
                mem_z2_next <= "00000000";
                mem_z3_next <= "00000000";
                
                first_bit_next <= '0';
                second_bit_next <= '0';
                
                o_mem_addr <= "0000000000000000"; 
                mem_add_next <= "0000000000000000";
                o_mem_en <= '0';
                o_mem_we <= '0';
                
                temp := "0000000000000000";                                
                conc := "0000000000000000"; 
              
            when S0 => 
                o_done <= '0'; -- azzero le uscite
                o_z0 <= "00000000";
                o_z1 <= "00000000";
                o_z2 <= "00000000";
                o_z3 <= "00000000";
                
                first_bit_next <= '0';  
                second_bit_next <= '0';
                
                o_mem_addr <= "0000000000000000"; -- azzero indirizzo di memoria
                mem_add_next <= "0000000000000000";
                o_mem_en <= '0';
                o_mem_we <= '0';
                
                temp := "0000000000000000";                                
                conc := "0000000000000000";

            when S1 =>  -- stato in cui leggo il primo bit in ingresso 
                first_bit_next <= i_w_reg;
    
            when S2 =>  -- stato in cui leggo il secondo bit in ingresso
                second_bit_next <= i_w_reg;
                                    
            when S3 => -- stato in cui leggo N bit di indirizzo di memoria
                conc := (0 downto 0 => i_w_reg, others => '0'); -- concatenazione di 0 con segnale letto in ingresso
                mem_add_next <= std_logic_vector(unsigned(conc) + unsigned(temp) + unsigned(temp)); -- "shift left": sommo bit letto (conc) a indirizzo x2 (temp+temp)         
            
            when S4 =>  
                o_mem_en <= '1'; -- abilito la memoria in lettura
                o_mem_we <= '0';    
                o_mem_addr <= mem_add_curr; -- indirizzo di memoria cercato 
                
            when s5 => -- stato in attesa che la memoria restituisca il dato (2ns)
                                 
            when s6 => -- stato in cui si salva il dato in uscita dalla memoria nel registro corretto
                if(first_bit_curr = '0' and second_bit_curr = '0') then 
                    mem_z0_next <= i_mem_data; -- cambia il valore di z0, mentre le altre uscite mantengono il valore precedente
                elsif(first_bit_curr = '0' and second_bit_curr = '1') then 
                    mem_z1_next <= i_mem_data; -- cambia il valore di z1
                elsif(first_bit_curr = '1' and second_bit_curr = '0') then 
                    mem_z2_next <= i_mem_data; -- cambia il valore di z2
                elsif(first_bit_curr = '1' and second_bit_curr = '1') then 
                    mem_z3_next <= i_mem_data; -- cambia il valore di z3
                end if;
                
            when s7 =>  -- stato in cui i valori delle uscite sono visibili (DONE=1)
                o_done <= '1';
                o_z0 <= mem_z0_curr;
                o_z1 <= mem_z1_curr;
                o_z2 <= mem_z2_curr;
                o_z3 <= mem_z3_curr;
                
        end case;
    end process;
    
end Behavioral;