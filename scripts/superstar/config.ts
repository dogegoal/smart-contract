type Config = {
  SuperstarAddress: string;
  MysteryBoxAddress: string;
  Payee?: string;
};

const BscTestnetScriptConfig: Config = {
  SuperstarAddress: "0xde7663697fb6372602eC50A7a3CdBe2Adc6268f4",
  MysteryBoxAddress: "0x4E4168E6923bEf08452Ea325d784aC7852f30521",
};

const BscScriptConfig: Config = {
  SuperstarAddress: "",
  MysteryBoxAddress: "",
};

export const ScriptConfig = BscTestnetScriptConfig;
