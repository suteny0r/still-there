# PlatformIO extra script (env:xiao_espdet): link esp-dl's prebuilt FlatBuffers model library.
# Added through LIBS so it lands after the espdl archive on the link line.
Import("env")
import os

env.Append(
    LIBPATH=[os.path.join(env.subst("$PROJECT_DIR"), "lib", "espdl", "fbs_loader", "lib", "esp32s3")],
    LIBS=["fbs_model"],
)
