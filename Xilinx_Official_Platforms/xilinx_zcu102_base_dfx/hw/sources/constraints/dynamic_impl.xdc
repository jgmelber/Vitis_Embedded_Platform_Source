# Copyright 2021 Xilinx Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Floorplanning
# ------------------------------------------------------------------------------

#placeholder
#set_false_path -to [get_pins -hierarchical -filter \{NAME =~ pfm_top_i/static_region/axi_intc_0/U0/INTC_CORE_I/*/D}]
set_property BEL MMCM [get_cells pfm_top_i/static_region/base_clocking/clkwiz_sysclks/inst/mmcme4_adv_inst]
set_property LOC MMCM_X0Y2 [get_cells pfm_top_i/static_region/base_clocking/clkwiz_sysclks/inst/mmcme4_adv_inst]
