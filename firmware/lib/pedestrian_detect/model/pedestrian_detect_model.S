.section .rodata.embedded
.balign 16
.global _binary_pedestrian_detect_espdl_start
_binary_pedestrian_detect_espdl_start:
.incbin "lib/pedestrian_detect/model/pedestrian_detect.espdl"
.global _binary_pedestrian_detect_espdl_end
_binary_pedestrian_detect_espdl_end:
.balign 16
