#######################################################################
# test Vector<T> ABI
#######################################################################

macro(extract_asm marker)
   execute_process(
      COMMAND grep -A100 ${marker}_start ${ASM}
      COMMAND grep -B100 ${marker}_end
      COMMAND sed -e "s/ *#.*$//"
      COMMAND grep -v -e ${marker}_ -e "^\\." -e "^ *$"
      OUTPUT_VARIABLE asm)
   string(STRIP "${asm}" asm)
   string(REPLACE "(%rip)" "" asm "${asm}")
   string(REPLACE "\t" " " asm "${asm}")
   string(REGEX REPLACE "  +" " " asm "${asm}")
endmacro()

extract_asm(vector_abi)

if("${IMPL}" STREQUAL SSE)
   set(reference "v?movaps .*a_v, %xmm0.*call.* v?movaps %xmm0, .*b_v")
elseif("${IMPL}" STREQUAL AVX OR "${IMPL}" STREQUAL AVX2)
   set(reference "vmovaps .*a_v, %ymm0.*call.* vmovaps %ymm0, .*b_v")
elseif("${IMPL}" STREQUAL MIC)
   set(reference "vmovaps .*a_v, %zmm0.*call.* vmovaps %zmm0, .*b_v")
else()
   message(FATAL_ERROR "Unknown IMPL '${IMPL}'")
endif()

if("${asm}" MATCHES "${reference}")
   message("PASS: Vector<T> ABI")
else()
   message(FATAL_ERROR "Failed.\n'${asm}'\n  does not match\n'${reference}'")
endif()

#######################################################################
# test Mask<T> ABI
#######################################################################
if("${IMPL}" STREQUAL MIC)
   set(reference "movzwl a_m, %edi.*call.*movw %ax, b_m")
else()
   string(REPLACE "_v" "_m" reference "${reference}")
endif()

extract_asm(mask_abi)
if("${asm}" MATCHES "${reference}")
   message("PASS: Mask<T> ABI")
else()
   message(FATAL_ERROR "Failed.\n'${asm}'\n  does not match\n'${reference}'")
endif()
