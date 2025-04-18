//===---------------- RISCVInstrInfoXQci.td ----------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the vendor extensions defined by QUALCOMM.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Operand and SDNode transformation definitions.
//===----------------------------------------------------------------------===//

def uimm5nonzero : RISCVOp<XLenVT>,
                   ImmLeaf<XLenVT, [{return (Imm != 0) && isUInt<5>(Imm);}]> {
  let ParserMatchClass = UImmAsmOperand<5, "NonZero">;
  let DecoderMethod = "decodeUImmNonZeroOperand<5>";
  let OperandType = "OPERAND_UIMM5_NONZERO";
}

def uimm5gt3 : RISCVOp<XLenVT>, ImmLeaf<XLenVT,
  [{return (Imm > 3) && isUInt<5>(Imm);}]> {
  let ParserMatchClass = UImmAsmOperand<5, "GT3">;
  let DecoderMethod = "decodeUImmOperand<5>";
  let OperandType = "OPERAND_UIMM5_GT3";
}

def uimm11 : RISCVUImmLeafOp<11>;

//===----------------------------------------------------------------------===//
// Instruction Formats
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Instruction Class Templates
//===----------------------------------------------------------------------===//

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in {
class QCILoad_ScaleIdx<bits<4> funct4, string opcodestr>
    : RVInstRBase<0b111, OPC_CUSTOM_0,
                  (outs GPR:$rd), (ins GPRMem:$rs1, GPRNoX0:$rs2, uimm3:$shamt),
                  opcodestr, "$rd, $rs1, $rs2, $shamt"> {
  bits<3> shamt;
  let Inst{31-28} = funct4;
  let Inst{27-25} = shamt;
}
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in {
// rd corresponds to the source for the store 'rs3' described in the spec.
class QCIStore_ScaleIdx<bits<4> funct4, string opcodestr>
    : RVInstRBase<0b110, OPC_CUSTOM_1, (outs),
                  (ins GPR:$rd, GPRMem:$rs1, GPRNoX0:$rs2, uimm3:$shamt),
                  opcodestr, "$rd, $rs1, $rs2, $shamt"> {
  bits<3> shamt;
  let Inst{31-28} = funct4;
  let Inst{27-25} = shamt;
}
}

class QCIRVInstR<bits<4> funct4, string opcodestr>
    : RVInstR<{0b000, funct4}, 0b011, OPC_CUSTOM_0, (outs GPRNoX0:$rd),
              (ins GPRNoX0:$rs1), opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

class QCIRVInstRR<bits<5> funct5, DAGOperand InTyRs1, string opcodestr>
    : RVInstR<{0b00, funct5}, 0b011, OPC_CUSTOM_0, (outs GPRNoX0:$rd),
              (ins InTyRs1:$rs1, GPRNoX0:$rs2), opcodestr, "$rd, $rs1, $rs2">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class QCISELECTIICC<bits<3> funct3, string opcodestr>
    : RVInstR4<0b00, funct3, OPC_CUSTOM_2, (outs GPRNoX0:$rd_wb),
               (ins GPRNoX0:$rd, GPRNoX0:$rs1, simm5:$simm1, simm5:$simm2),
               opcodestr, "$rd, $rs1, $simm1, $simm2"> {
  let Constraints = "$rd = $rd_wb";
  bits<5> simm1;
  bits<5> simm2;

  let rs3 = simm2;
  let rs2 = simm1;
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class QCISELECTICC<bits<3> funct3, string opcodestr>
    : RVInstR4<0b01, funct3, OPC_CUSTOM_2, (outs GPRNoX0:$rd_wb),
               (ins GPRNoX0:$rd, GPRNoX0:$rs1, GPRNoX0:$rs2, simm5:$simm2),
               opcodestr, "$rd, $rs1, $rs2, $simm2"> {
  let Constraints = "$rd = $rd_wb";
  bits<5> simm2;

  let rs3 = simm2;
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class QCISELECTCCI<bits<3> funct3, string opcodestr>
    : RVInstR4<0b10, funct3, OPC_CUSTOM_2, (outs GPRNoX0:$rd_wb),
               (ins GPRNoX0:$rd, simm5:$imm, GPRNoX0:$rs2, GPRNoX0:$rs3),
               opcodestr, "$rd, $imm, $rs2, $rs3"> {
  let Constraints = "$rd = $rd_wb";
  bits<5> imm;

  let rs1 = imm;
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class QCISELECTICCI<bits<3> funct3, string opcodestr>
    : RVInstR4<0b11, funct3, OPC_CUSTOM_2, (outs GPRNoX0:$rd_wb),
               (ins GPRNoX0:$rd, simm5:$imm, GPRNoX0:$rs2, simm5:$simm2),
               opcodestr, "$rd, $imm, $rs2, $simm2"> {
  let Constraints = "$rd = $rd_wb";
  bits<5> imm;
  bits<5> simm2;

  let rs3 = simm2;
  let rs1 = imm;
}

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
class QCILoadMultiple<bits<2> funct2, DAGOperand InTyRs2, string opcodestr>
    : RVInstRBase<0b111, OPC_CUSTOM_0, (outs GPRNoX0:$rd),
                  (ins GPR:$rs1, InTyRs2:$rs2, uimm7_lsb00:$imm),
                  opcodestr, "$rd, $rs2, ${imm}(${rs1})"> {
  bits<7> imm;
  let Inst{31-25} = {funct2, imm{6-2}};
}


// rd corresponds to the source for the store 'rs3' described in the spec.
let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
class QCIStoreMultiple<bits<2> funct2, DAGOperand InTyRs2, string opcodestr>
    : RVInstRBase<0b111, OPC_CUSTOM_1, (outs),
                  (ins GPR:$rd, GPR:$rs1, InTyRs2:$rs2, uimm7_lsb00:$imm),
                  opcodestr, "$rd, $rs2, ${imm}(${rs1})"> {
  bits<7> imm;
  let Inst{31-25} = {funct2, imm{6-2}};
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class QCILICC<bits<3> funct3, bits<2> funct2, DAGOperand InTyRs2, string opcodestr>
    : RVInstRBase<funct3, OPC_CUSTOM_2, (outs GPRNoX0:$rd_wb),
                  (ins GPRNoX0:$rd, GPRNoX0:$rs1, InTyRs2:$rs2, simm5:$simm),
                  opcodestr, "$rd, $rs1, $rs2, $simm"> {
  let Constraints = "$rd = $rd_wb";
  bits<5> simm;

  let Inst{31-25} = {simm, funct2};
}

//===----------------------------------------------------------------------===//
// Instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasVendorXqcicsr, IsRV32], DecoderNamespace = "Xqcicsr" in {
let hasSideEffects = 1, mayLoad = 0, mayStore = 0 in {
  def QC_CSRRWR : RVInstR<0b1000110, 0b000, OPC_SYSTEM, (outs GPR:$rd),
                          (ins GPR:$rs1, GPRNoX0:$rs2), "qc.csrrwr",
                          "$rd, $rs1, $rs2">;

  def QC_CSRRWRI : RVInstR<0b1000111, 0b000, OPC_SYSTEM, (outs GPR:$rd),
                           (ins uimm5:$rs1, GPRNoX0:$rs2), "qc.csrrwri",
                           "$rd, $rs1, $rs2">;
} // hasSideEffects = 1, mayLoad = 0, mayStore = 0
} // Predicates = [HasVendorXqcicsr, IsRV32], DecoderNamespace = "Xqcicsr"

let Predicates = [HasVendorXqcisls, IsRV32], DecoderNamespace = "Xqcisls" in {
  def  QC_LRB  : QCILoad_ScaleIdx<0b1000, "qc.lrb">;
  def  QC_LRH  : QCILoad_ScaleIdx<0b1001, "qc.lrh">;
  def  QC_LRW  : QCILoad_ScaleIdx<0b1010, "qc.lrw">;
  def  QC_LRBU : QCILoad_ScaleIdx<0b1011, "qc.lrbu">;
  def  QC_LRHU : QCILoad_ScaleIdx<0b1100, "qc.lrhu">;

  def  QC_SRB  : QCIStore_ScaleIdx<0b1101, "qc.srb">;
  def  QC_SRH  : QCIStore_ScaleIdx<0b1110, "qc.srh">;
  def  QC_SRW  : QCIStore_ScaleIdx<0b1111, "qc.srw">;
} // Predicates = [HasVendorXqcisls, IsRV32], DecoderNamespace = "Xqcisls"

let Predicates = [HasVendorXqcia, IsRV32], DecoderNamespace = "Xqcia" in {
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
  def QC_SLASAT : QCIRVInstRR<0b01010, GPRNoX0, "qc.slasat">;
  def QC_SLLSAT : QCIRVInstRR<0b01100, GPRNoX0, "qc.sllsat">;
  def QC_ADDSAT : QCIRVInstRR<0b01110, GPRNoX0, "qc.addsat">;
  def QC_ADDUSAT : QCIRVInstRR<0b01111, GPRNoX0, "qc.addusat">;
  def QC_SUBSAT : QCIRVInstRR<0b10000, GPRNoX0, "qc.subsat">;
  def QC_SUBUSAT : QCIRVInstRR<0b10001, GPRNoX0, "qc.subusat">;

  def QC_WRAP : QCIRVInstRR<0b10010, GPR, "qc.wrap">;
  def QC_WRAPI : RVInstI<0b000, OPC_CUSTOM_0, (outs GPRNoX0:$rd),
                         (ins GPRNoX0:$rs1, uimm11:$imm11), "qc.wrapi",
                         "$rd, $rs1, $imm11"> {
    bits<11> imm11;

    let imm12 = {0b0, imm11};
  }

  def QC_NORM : QCIRVInstR<0b0111, "qc.norm">;
  def QC_NORMU : QCIRVInstR<0b1000, "qc.normu">;
  def QC_NORMEU : QCIRVInstR<0b1001, "qc.normeu">;
} // hasSideEffects = 0, mayLoad = 0, mayStore = 0
} // Predicates = [HasVendorXqcia, IsRV32], DecoderNamespace = "Xqcia"

let Predicates = [HasVendorXqciac, IsRV32], DecoderNamespace = "Xqciac" in {
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
  def QC_C_MULADDI : RVInst16CL<0b001, 0b10, (outs GPRC:$rd_wb),
                               (ins GPRC:$rd, GPRC:$rs1, uimm5:$uimm),
                               "qc.c.muladdi", "$rd, $rs1, $uimm"> {
    let Constraints = "$rd = $rd_wb";
    bits<5> uimm;

    let Inst{12-10} = uimm{3-1};
    let Inst{6} = uimm{0};
    let Inst{5} = uimm{4};
  }

  def QC_MULADDI : RVInstI<0b110, OPC_CUSTOM_0, (outs GPRNoX0:$rd_wb),
                           (ins GPRNoX0:$rd, GPRNoX0:$rs1, simm12:$imm12),
                           "qc.muladdi", "$rd, $rs1, $imm12"> {
    let Constraints = "$rd = $rd_wb";
  }

  def QC_SHLADD : RVInstRBase<0b011, OPC_CUSTOM_0, (outs GPRNoX0:$rd),
                              (ins GPRNoX0:$rs1, GPRNoX0:$rs2, uimm5gt3:$shamt),
                              "qc.shladd", "$rd, $rs1, $rs2, $shamt"> {
    bits<5> shamt;

    let Inst{31-30} = 0b01;
    let Inst{29-25} = shamt;
  }

} // hasSideEffects = 0, mayLoad = 0, mayStore = 0
} // Predicates = [HasVendorXqciac, IsRV32], DecoderNamespace = "Xqciac"

let Predicates = [HasVendorXqcics, IsRV32], DecoderNamespace = "Xqcics" in {
  def QC_SELECTIIEQ : QCISELECTIICC <0b010, "qc.selectiieq">;
  def QC_SELECTIINE : QCISELECTIICC <0b011, "qc.selectiine">;
  def QC_SELECTIEQ  : QCISELECTICC  <0b010, "qc.selectieq">;
  def QC_SELECTINE  : QCISELECTICC  <0b011, "qc.selectine">;
  def QC_SELECTEQI  : QCISELECTCCI  <0b010, "qc.selecteqi">;
  def QC_SELECTNEI  : QCISELECTCCI  <0b011, "qc.selectnei">;
  def QC_SELECTIEQI : QCISELECTICCI <0b010, "qc.selectieqi">;
  def QC_SELECTINEI : QCISELECTICCI <0b011, "qc.selectinei">;
} // Predicates = [HasVendorXqcics, IsRV32], DecoderNamespace = "Xqcics"

let Predicates = [HasVendorXqcilsm, IsRV32], DecoderNamespace = "Xqcilsm" in {
    def QC_SWM : QCIStoreMultiple<0b00, GPRNoX0, "qc.swm">;
    def QC_SWMI : QCIStoreMultiple<0b01, uimm5nonzero, "qc.swmi">;
    def QC_SETWM : QCIStoreMultiple<0b10, GPRNoX0, "qc.setwm">;
    def QC_SETWMI : QCIStoreMultiple<0b11, uimm5nonzero, "qc.setwmi">;

    def QC_LWM : QCILoadMultiple<0b00, GPRNoX0, "qc.lwm">;
    def QC_LWMI : QCILoadMultiple<0b01, uimm5nonzero, "qc.lwmi">;
} // Predicates = [HasVendorXqcilsm, IsRV32], DecoderNamespace = "Xqcilsm"

let Predicates = [HasVendorXqcicli, IsRV32], DecoderNamespace = "Xqcicli" in {
  def QC_LIEQ    : QCILICC<0b000, 0b01, GPRNoX0, "qc.lieq">;
  def QC_LINE    : QCILICC<0b001, 0b01, GPRNoX0, "qc.line">;
  def QC_LILT    : QCILICC<0b100, 0b01, GPRNoX0, "qc.lilt">;
  def QC_LIGE    : QCILICC<0b101, 0b01, GPRNoX0, "qc.lige">;
  def QC_LILTU   : QCILICC<0b110, 0b01, GPRNoX0, "qc.liltu">;
  def QC_LIGEU   : QCILICC<0b111, 0b01, GPRNoX0, "qc.ligeu">;

  def QC_LIEQI   : QCILICC<0b000, 0b11, simm5, "qc.lieqi">;
  def QC_LINEI   : QCILICC<0b001, 0b11, simm5, "qc.linei">;
  def QC_LILTI   : QCILICC<0b100, 0b11, simm5, "qc.lilti">;
  def QC_LIGEI   : QCILICC<0b101, 0b11, simm5, "qc.ligei">;
  def QC_LILTUI  : QCILICC<0b110, 0b11, uimm5, "qc.liltui">;
  def QC_LIGEUI  : QCILICC<0b111, 0b11, uimm5, "qc.ligeui">;
} // Predicates = [HasVendorXqcicli, IsRV32], DecoderNamespace = "Xqcicli"

//===----------------------------------------------------------------------===//
// Aliases
//===----------------------------------------------------------------------===//

let Predicates = [HasVendorXqcilsm, IsRV32] in {
let EmitPriority = 0 in {
  def : InstAlias<"qc.swm $rs3, $rs2, (${rs1})",
                  (QC_SWM GPR:$rs3, GPR:$rs1, GPRNoX0:$rs2, 0)>;
  def : InstAlias<"qc.swmi $rs3, $length, (${rs1})",
                  (QC_SWMI GPR:$rs3, GPR:$rs1, uimm5nonzero:$length, 0)>;
  def : InstAlias<"qc.setwm $rs3, $rs2, (${rs1})",
                  (QC_SETWM GPR:$rs3, GPR:$rs1, GPRNoX0:$rs2, 0)>;
  def : InstAlias<"qc.setwmi $rs3, $length, (${rs1})",
                  (QC_SETWMI GPR:$rs3, GPR:$rs1, uimm5nonzero:$length, 0)>;
  def : InstAlias<"qc.lwm $rd, $rs2, (${rs1})",
                  (QC_LWM GPRNoX0:$rd, GPR:$rs1, GPRNoX0:$rs2, 0)>;
  def : InstAlias<"qc.lwmi $rd, $length, (${rs1})",
                  (QC_LWMI GPRNoX0:$rd, GPR:$rs1, uimm5nonzero:$length, 0)>;
} // EmitPriority = 0
} // Predicates = [HasVendorXqcilsm, IsRV32]
