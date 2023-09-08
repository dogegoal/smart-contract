type Config = {
  EarlyPassAddress: string;
  EarlyAccessAddress: string;
  EarlyStarterPassPrice: string;
  EarlyProPassPrice: string;
  Payee?: string;
  Beneficary?: string;
};

const BscTestnetScriptConfig: Config = {
  EarlyPassAddress: "0xB1Ef0395540e8d5b2657E777e9482990D96F2fA4",
  EarlyAccessAddress: "0x8A398ea1626d6cB649B0203072Ec486F52EF9F8f",
  EarlyStarterPassPrice: "0.0025",
  EarlyProPassPrice: "0.0075",
};

const BscScriptConfig: Config = {
  EarlyPassAddress: "0x338A3E66Ca8Be4464699E83E76d36c91eb80583c",
  EarlyAccessAddress: "0xC9F33F1f20Abc94FB7115331e135A70c6b440E47",
  EarlyStarterPassPrice: "0.0025",
  EarlyProPassPrice: "0.0075",
  Payee: "0x8c809221684EA647d2dD26f230217fabcFd93Ea6",
  Beneficary: "0x9709E3D623090957742a9c3CCBcA19F09877F457",
};

export const ScriptConfig = BscTestnetScriptConfig;
