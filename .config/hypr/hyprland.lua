--------------------------------
----       VARIABLES        ----
--------------------------------
----      NON ELIMINAR      ----
---- SOLO MODIFICAR VALORES ----
--------------------------------

Gallaecia = {
  mainMod = "SUPER",

  terminal = "{{terminal}}",
  editor = "{{editor}}",
  ide = "{{ide}}",
  navegador = "{{navegador}}",
  explorador_de_arquivos = "{{explorador_de_arquivos}}",
}

dofile(os.getenv("HOME") .. "/.local/share/gallaecia-dots/hypr/gallaecia.lua")

-------------------
---- MONITORES ----
-------------------

-- hl.monitor({ output = "HDMI-A-1/DP-1", mode = "1920x1080@144", position = "0x0", scale = "1" })

------------------------------
---- VARIABLES DE ENTORNO ----
------------------------------

-- hl.env("VARIABLE", "valor")

--------------------
---- AUTOINICIO ----
--------------------

hl.on("hyprland.start", function ()
    -- hl.exec_cmd("comando-ou-app")
end)

--------------------
----- PERMISOS -----
--------------------



-----------------------
---- LOOK AND FEEL ----
-----------------------



----------------------
----  MISCELÁNEO  ----
----------------------



-----------------
---- ENTRADA ----
-----------------



----------------------------
---- ATALLOS DE TECLADO ----
----------------------------

-- Aplicacións
hl.bind(Gallaecia.mainMod .. " + T", hl.dsp.exec_cmd(Gallaecia.terminal))
hl.bind(Gallaecia.mainMod .. " + B", hl.dsp.exec_cmd(Gallaecia.navegador))
hl.bind(Gallaecia.mainMod .. " + E", hl.dsp.exec_cmd(Gallaecia.explorador_de_arquivos))
hl.bind(Gallaecia.mainMod .. " + C", hl.dsp.exec_cmd(Gallaecia.ide))

-- hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("comando-ou-app"))


-----------------------------------------
---- VENTANAS E ESPACIOS DE TRABALLO ----
-----------------------------------------



------------------------
----    REQUIRES    ----
------------------------
----  NON ELIMINAR  ----
------------------------

-- Importar cores de noctalia
require("noctalia").apply_theme()