library vunit_lib;
    context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    use osvvm.TbUtilPkg.all;

library universal;
    use universal.CommonFunctions.all;
    use universal.CommonTypes.all;

library tb;
    use tb.RiscVTbTools.all;

entity InstructionMemory is
    port (
        i_clk          : in std_logic;
        i_resetn       : in std_logic;
        i_instr_addr   : in std_logic_vector(31 downto 0);
        i_instr_ren    : in std_logic;
        i_instr_wen    : in std_logic_vector(3 downto 0);
        i_instr_wdata  : in std_logic_vector(31 downto 0);
        o_instr_rdata  : out std_logic_vector(31 downto 0);
        o_instr_rvalid : out std_logic
    );
end entity InstructionMemory;

architecture rtl of InstructionMemory is
    type memory_address_t;
    type memory_address_ptr_t is access memory_address_t;
    type memory_address_t is record
        address : std_logic_vector(31 downto 0);
        data    : std_logic_vector(31 downto 0);
        ptr     : memory_address_ptr_t;
    end record memory_address_t;
begin
    
    InternalTestStructure: process(i_clk)
        variable memory_ptr     : memory_address_ptr_t;
        variable old_memory_ptr : memory_address_ptr_t;
        variable registers      : register_map_t := generate_registers(x"00000001");
    begin
        if rising_edge(i_clk) then
            if (i_resetn = '0') then
                -- delete history? would create an entirely new program
            else
                if (i_instr_ren = '1') then
                    if (memory_ptr = null) then
                        memory_ptr := 
                            new memory_address_t'(
                                address=>i_instr_addr, 
                                data=>generate_instruction(registers), 
                                ptr=>null);
                        o_instr_rdata <= memory_ptr.data;
                        o_instr_rvalid <= '1';
                    else
                        old_memory_ptr := memory_ptr;
                        while (memory_ptr.address /= i_instr_addr and memory_ptr.ptr /= null) loop
                            memory_ptr := memory_ptr.ptr;
                        end loop;

                        if (memory_ptr.address = i_instr_addr) then
                            o_instr_rdata <= memory_ptr.data;
                        elsif (memory_ptr.ptr /= null) then
                            memory_ptr.ptr := 
                                new memory_address_t'(
                                    address=>i_instr_addr, 
                                    data=>generate_instruction(registers), 
                                    ptr=>null);
                            o_instr_rdata <= memory_ptr.ptr.data;
                        end if;
                        o_instr_rvalid <= '1';
                        memory_ptr := old_memory_ptr;
                    end if;
                else
                    o_instr_rdata <= x"00000000";
                    o_instr_rvalid <= '0';
                end if;
            end if;
        end if;
    end process InternalTestStructure;

    Checkers: process(i_instr_addr, i_instr_wen, i_instr_wdata)
    begin
        --report to_hstring(i_instr_addr);
        check(i_instr_addr(1) /= '1' and i_instr_addr(0) /= '1');
        --report to_hstring(i_instr_wen);
        check(i_instr_wen(3) /= '1' 
            and i_instr_wen(2) /= '1' 
            and i_instr_wen(1) /= '1'
            and i_instr_wen(0) /= '1');
    end process Checkers;
    
end architecture rtl;