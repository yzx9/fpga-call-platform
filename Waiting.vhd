LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

LIBRARY work;
USE work.config.ALL;

-- 数据源 -> Waiting -> 发射器 -> 接收器
-- 不处理 队列为满 的错误, 交由发射器处理
ENTITY Waiting IS
  GENERIC (
    GROUP_FLAG : STD_LOGIC_VECTOR(FLAG_GROUP_WIDTH - 1 DOWNTO 0) := (OTHERS => '0') -- flag width
  );
  PORT (
    clock : IN std_logic;
    reset : IN std_logic;
    button : IN std_logic; -- 用户取号

    pull : OUT std_logic; -- 申请取号
    enable_pull : IN std_logic; -- 允许取号

    push : OUT std_logic; -- 申请发送
    pushed : IN std_logic; -- 已发送

    data_in : IN std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
    data_out : OUT std_logic_vector(RAM_WIDTH - 1 DOWNTO 0)
  );
END Waiting;

ARCHITECTURE arch OF Waiting IS
  TYPE states IS(idle, pulling, pulled, pushing, success, queue_full);
  SIGNAL present_state : states;
  SIGNAL next_state : states;

  SIGNAL data : std_logic_vector(RAM_WIDTH - 1 DOWNTO 0);
  CONSTANT DATA_DEFAULT : std_logic_vector(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');

  -- jump next state
  FUNCTION ifElse(
    condition : std_logic;
    onTrue : states;
    onFalse : states
  ) RETURN states IS
  BEGIN
    IF (condition = '1') THEN
      RETURN onTrue;
    ELSE
      RETURN onFalse;
    END IF;
  END FUNCTION;
BEGIN
  -- clock trigger
  PROCESS (clock)
  BEGIN
    IF (reset = '1') THEN
      present_state <= idle;
    ELSIF (clock'event AND clock = '1') THEN
      present_state <= next_state;
    END IF;
  END PROCESS;

  -- state change
  PROCESS (present_state, button, enable_pull, pushed)
  BEGIN
    CASE present_state IS
      WHEN idle =>
        next_state <= ifElse(button, pulling, idle);

      WHEN pulling =>
        next_state <= ifElse(enable_pull, pulled, pulling);

      WHEN pulled =>
        next_state <= pushing;

      WHEN pushing =>
        next_state <= ifElse(pushed, success, pushing);

      WHEN success =>
        next_state <= idle;

      WHEN OTHERS =>
        next_state <= idle;
    END CASE;
  END PROCESS;

  -- state events
  PROCESS (present_state, data_in, data)
  BEGIN
    -- make latches: data
    push <= '0';
    pull <= '0';
    data_out <=
      FLAG_SCREEN_WAITING -- 2 bit
      & FLAG_GROUP_FREE -- 4 bit
      & FLAG_ERROR_UNKNOWN -- 2 bit
      & DATA_DEFAULT;

    CASE present_state IS
      WHEN idle => NULL;

      WHEN pulling =>
        pull <= '1';
        data <=
          FLAG_SCREEN_WAITING -- 2 bit
          & GROUP_FLAG -- 4 bit
          & FLAG_ERROR_FREE -- 2 bit
          & data_in;

      WHEN pulled =>
        pull <= '0';

      WHEN pushing =>
        push <= '1';
        data_out <= data;

      WHEN success =>
        push <= '0';

      WHEN OTHERS => NULL;

    END CASE;
  END PROCESS;
END arch;