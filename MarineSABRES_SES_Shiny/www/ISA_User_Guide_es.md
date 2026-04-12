<div class="alert alert-info" role="alert">
<strong>Nota:</strong> Esta guía fue traducida automáticamente del inglés utilizando Claude AI.
Si detecta errores, comuníquelos al equipo del proyecto MarineSABRES.
<em>Estado de la traducción: Borrador (traducción automática, pendiente de revisión)</em>
</div>

# Módulo de Entrada de Datos ISA - Guía del Usuario {#isa-data-entry-module---user-guide}

## Herramienta de Análisis de Sistemas Socioecológicos MarineSABRES {#marinesabres-social-ecological-systems-analysis-tool}

**Version:** 1.0
**Última actualización:** Abril 2026

---

## Tabla de Contenidos {#table-of-contents}

1. [Introducción](#introduction)
2. [Primeros Pasos](#getting-started)
3. [El Marco DAPSI(W)R(M)](#the-dapsiwrm-framework)
4. [Flujo de Trabajo Paso a Paso](#step-by-step-workflow)
5. [Guía Ejercicio por Ejercicio](#exercise-by-exercise-guide)
6. [Trabajar con Kumu](#working-with-kumu)
7. [Gestión de Datos](#data-management)
8. [Consejos y Mejores Prácticas](#tips-and-best-practices)
9. [Resolución de Problemas](#troubleshooting)
10. [Glosario](#glossary)

---

## Introducción {#introduction}

### ¿Qué es el Módulo ISA?

El módulo de Entrada de Datos del Análisis Integrado de Sistemas (ISA) es una herramienta integral para analizar sistemas socioecológicos marinos utilizando el marco DAPSI(W)R(M). Le guía a través de un proceso sistemático de 13 ejercicios para:

- Mapear la estructura de su sistema socioecológico marino
- Identificar relaciones causales entre las actividades humanas y los cambios ecosistémicos
- Comprender los bucles de retroalimentación y la dinámica del sistema
- Identificar puntos de apalancamiento para intervenciones políticas
- Crear Diagramas de Bucle Causal (CLD) visuales
- Validar hallazgos con las partes interesadas

### ¿Quién Debería Usar Esta Herramienta?

- Gestores de ecosistemas marinos y responsables de políticas
- Científicos e investigadores ambientales
- Planificadores de zonas costeras
- Profesionales de la conservación
- Grupos de partes interesadas involucrados en la gestión marina
- Estudiantes que estudian sistemas socioecológicos marinos

### Características Principales

- **Flujo de trabajo estructurado:** 13 ejercicios le guían sistemáticamente a través del análisis
- **Ayuda integrada:** Ayuda contextual para cada ejercicio
- **Exportación de datos:** Exportación a Excel y software de visualización Kumu
- **Gráficos BOT:** Visualice dinámicas temporales con gráficos de Comportamiento a lo Largo del Tiempo
- **Flexible:** Importe/exporte datos, guarde el progreso, colabore con equipos

---

## Primeros Pasos {#getting-started}

### Acceso al Módulo ISA

1. Inicie la aplicación MarineSABRES Shiny
2. Desde el menú lateral, seleccione **"Entrada de Datos ISA"**
3. Verá la interfaz principal de ISA con las pestañas de ejercicios

### Descripción General de la Interfaz

La interfaz del módulo ISA consta de:

- **Encabezado:** Título y descripción del marco con botón de ayuda principal
- **Pestañas de Ejercicios:** 13 ejercicios más gráficos BOT y Gestión de Datos
- **Botones de Ayuda:** Haga clic en el icono de ayuda (?) en cualquier ejercicio para obtener orientación detallada
- **Formularios de Entrada:** Formularios dinámicos para introducir datos
- **Tablas de Datos:** Vea sus datos introducidos en tablas ordenables y con función de búsqueda
- **Botones de Guardar:** Guarde su trabajo después de completar cada ejercicio

### Obtener Ayuda

**Guía Principal del Marco:** Haga clic en el botón "Guía del Marco ISA" en la parte superior para obtener una visión general de DAPSI(W)R(M).

**Ayuda Específica del Ejercicio:** Haga clic en el botón "Ayuda" dentro de cada pestaña de ejercicio para obtener instrucciones detalladas, ejemplos y consejos.

---

## El Marco DAPSI(W)R(M) {#the-dapsiwrm-framework}

### Descripción General

DAPSI(W)R(M) es un marco causal para analizar sistemas socioecológicos marinos:

- **D** - **Factores Impulsores (Drivers):** Fuerzas subyacentes que motivan las actividades humanas (económicas, sociales, tecnológicas, políticas)
- **A** - **Actividades (Activities):** Usos humanos de los ambientes marinos y costeros
- **P** - **Presiones (Pressures):** Factores de estrés directos sobre el medio ambiente marino
- **S** - **Cambios de Estado (State Changes):** Cambios en la condición del ecosistema, representados a través de:
  - **W** - **Impacto en el Bienestar (Welfare):** Bienes y Beneficios derivados del ecosistema
  - **ES** - **Servicios Ecosistémicos (Ecosystem Services):** Beneficios que los ecosistemas proporcionan a las personas
  - **MPF** - **Procesos y Funcionamiento Marino (Marine Processes & Functioning):** Procesos biológicos, químicos y físicos
- **R** - **Respuestas (Responses):** Acciones de la sociedad para abordar los problemas
- **M** - **Medidas (Measures):** Intervenciones políticas y acciones de gestión

### La Cadena Causal

El marco representa una cadena causal:

```
Factores Impulsores → Actividades → Presiones → Cambios de Estado (MPF → ES → Bienestar) → Respuestas
    ↑                                                                                            ↓
    └──────────────────────── Bucle de Retroalimentación ───────────────────────────────────────┘
```

### ¿Por Qué DAPSI(W)R(M)?

- **Sistemático:** Asegura una cobertura completa de todos los componentes del sistema
- **Causal:** Establece vínculos explícitos entre las acciones humanas y los cambios ecosistémicos
- **Circular:** Captura los bucles de retroalimentación entre el ecosistema y la sociedad
- **Relevante para las políticas:** Se vincula directamente con los puntos de intervención (Respuestas/Medidas)
- **Ampliamente utilizado:** Marco estándar en la política marina europea (MSFD, WFD)

---

## Flujo de Trabajo Paso a Paso {#step-by-step-workflow}

### Secuencia Recomendada

Siga los ejercicios en orden para obtener mejores resultados:

**Fase 1: Delimitación (Exercise 0)**
- Defina los límites y el contexto de su estudio de caso

**Fase 2: Construcción de la Cadena Causal (Exercises 1-5)**
- Trabaje hacia atrás desde los impactos en el bienestar hasta los factores impulsores raíz
- Exercise 1: Bienes y Beneficios (lo que la gente valora)
- Exercise 2a: Servicios Ecosistémicos (cómo los ecosistemas proporcionan beneficios)
- Exercise 2b: Procesos Marinos (funciones ecológicas subyacentes)
- Exercise 3: Presiones (factores de estrés sobre el ecosistema)
- Exercise 4: Actividades (usos humanos del medio ambiente marino)
- Exercise 5: Factores Impulsores (fuerzas que motivan las actividades)

**Fase 3: Cerrar el Bucle (Exercise 6)**
- Conecte los factores impulsores de vuelta a los bienes y beneficios para crear bucles de retroalimentación

**Fase 4: Visualización (Exercises 7-9)**
- Cree Diagramas de Bucle Causal en Kumu
- Exporte y refine su modelo visual

**Fase 5: Análisis y Validación (Exercises 10-12)**
- Refine su modelo (clarificación)
- Identifique puntos de apalancamiento
- Valide con las partes interesadas

**Continuo: Gráficos BOT**
- Añada datos temporales cuando estén disponibles
- Úselos para validar hipótesis causales

### Requisitos de Tiempo

**Análisis rápido:** 4-8 horas (estudio de caso simplificado, equipo pequeño)

**Análisis integral:** 2-4 días (estudio de caso complejo, participación de partes interesadas)

**Proceso participativo completo:** 1-2 semanas (múltiples talleres, validación extensa)

### Trabajo en Equipo

**Trabajo individual:**
- Una persona introduce los datos basándose en revisión bibliográfica y conocimiento experto

**Trabajo colaborativo:**
- Exporte/importe archivos Excel para compartir datos
- Use las funciones colaborativas de Kumu para el desarrollo del CLD
- Realice talleres para recopilar aportaciones para los ejercicios

---

## Guía Ejercicio por Ejercicio {#exercise-by-exercise-guide}

### Exercise 0: Desglosar la Complejidad e Impactos en el Bienestar

**Objetivo:** Establecer el contexto y los límites de su análisis.

**Qué Introducir:**
- Nombre del Estudio de Caso
- Breve Descripción
- Ámbito Geográfico (p. ej., "Mar Báltico", "Costa del Atlántico Norte")
- Ámbito Temporal (p. ej., "2000-2024")
- Impactos en el Bienestar (observaciones iniciales)
- Partes Interesadas Clave

**Consejos:**
- Sea completo pero conciso
- Considere perspectivas diversas (ambiental, económica, social, cultural)
- Incluya tanto beneficios como costes
- Enumere a todas las partes interesadas afectadas y tomadoras de decisiones

**Ejemplo:**
```
Caso: Pesquerías Comerciales del Mar Báltico
Ámbito Geográfico: Cuenca del Mar Báltico
Ámbito Temporal: 2000-2024
Impactos en el Bienestar: Ingresos por captura de peces, empleo, seguridad alimentaria,
                          patrimonio cultural, disminución de poblaciones
Partes Interesadas: Pescadores comerciales, comunidades costeras, procesadores,
                    consumidores, ONG, gestores pesqueros, responsables de políticas de la UE
```

---

### Exercise 1: Especificación de Bienes y Beneficios (G&B)

**Objetivo:** Identificar lo que las personas valoran del ecosistema marino.

**Qué Introducir para Cada Bien/Beneficio:**
- **Nombre:** Nombre claro y específico (p. ej., "Captura comercial de bacalao")
- **Tipo:** Aprovisionamiento / Regulación / Cultural / Soporte
- **Descripción:** Qué proporciona este beneficio
- **Parte Interesada:** ¿Quién se beneficia?
- **Importancia:** Alta / Media / Baja
- **Tendencia:** En aumento / Estable / En disminución / Desconocida

**Cómo Usar:**
1. Haga clic en "Añadir Bien/Beneficio"
2. Complete todos los campos
3. Haga clic en "Guardar Exercise 1" para actualizar la tabla
4. Cada G&B recibe automáticamente un ID único (GB001, GB002, etc.)

**Ejemplos:**

| Nombre | Tipo | Parte Interesada | Importancia |
|--------|------|------------------|-------------|
| Desembarques de pesca comercial | Aprovisionamiento | Pescadores, consumidores | Alta |
| Recreación costera | Cultural | Turistas, residentes | Alta |
| Protección contra marejadas | Regulación | Propietarios de inmuebles costeros | Alta |
| Secuestro de carbono | Regulación | Sociedad global | Media |

**Consejos:**
- Sea específico: "Pesquería comercial de bacalao" no solo "pesca"
- Incluya beneficios comercializados (venta de pescado) y no comercializados (recreación)
- Considere beneficios para diferentes grupos de partes interesadas
- Piense en sinergias y compensaciones

---

### Exercise 2a: Servicios Ecosistémicos (ES) que Afectan a Bienes y Beneficios

**Objetivo:** Identificar la capacidad del ecosistema para generar beneficios.

**Qué Introducir para Cada Servicio Ecosistémico:**
- **Nombre:** Nombre del servicio
- **Tipo:** Clasificación del servicio
- **Descripción:** Cómo funciona
- **Vinculado a G&B:** Seleccione del menú desplegable (bienes/beneficios del Ej. 1)
- **Mecanismo:** ¿Cómo produce este servicio el beneficio?
- **Confianza:** Alta / Media / Baja

**Entender ES vs G&B:**
- **Servicio Ecosistémico:** El potencial/capacidad (p. ej., "Productividad de poblaciones de peces")
- **Bien/Beneficio:** El beneficio realizado (p. ej., "Captura comercial de peces")

**Cómo Usar:**
1. Haga clic en "Añadir Servicio Ecosistémico"
2. Complete los campos
3. Seleccione qué G&B apoya este ES (el menú desplegable muestra todos los G&B del Exercise 1)
4. Haga clic en "Guardar Exercise 2a"

**Ejemplos:**

| Nombre del ES | Vinculado a G&B | Mecanismo |
|---------------|-----------------|-----------|
| Reclutamiento de poblaciones de peces | Captura comercial de peces | Éxito reproductivo → biomasa pescable |
| Filtración por moluscos | Calidad del agua para turismo | Mejillones filtran partículas → agua clara |
| Hábitat de praderas marinas | Refugio para especies comerciales | Refugio para juveniles → población adulta |

**Consejos:**
- Un G&B puede estar respaldado por múltiples ES
- Un ES puede respaldar múltiples G&B
- Describa claramente el mecanismo (facilita la validación)
- Use conocimiento científico y aportaciones de las partes interesadas

---

### Exercise 2b: Procesos y Funcionamiento Marino (MPF)

**Objetivo:** Identificar los procesos ecológicos fundamentales que sustentan los servicios ecosistémicos.

**Qué Introducir para Cada Proceso Marino:**
- **Nombre:** Nombre del proceso
- **Tipo:** Biológico / Químico / Físico / Ecológico
- **Descripción:** Qué hace este proceso
- **Vinculado a ES:** Seleccione del menú desplegable (ES del Ej. 2a)
- **Mecanismo:** ¿Cómo genera este proceso el servicio?
- **Escala Espacial:** Dónde ocurre (local/regional/a escala de cuenca)

**Tipos de Procesos Marinos:**
- **Biológicos:** Producción primaria, depredación, reproducción, migración
- **Químicos:** Ciclo de nutrientes, secuestro de carbono, regulación del pH
- **Físicos:** Circulación del agua, transporte de sedimentos, acción del oleaje
- **Ecológicos:** Estructura del hábitat, dinámica de la red trófica, biodiversidad

**Cómo Usar:**
1. Haga clic en "Añadir Proceso Marino"
2. Complete los campos
3. Seleccione qué ES apoya este MPF
4. Haga clic en "Guardar Exercise 2b"

**Ejemplos:**

| Nombre del MPF | Tipo | Vinculado a ES | Mecanismo |
|----------------|------|----------------|-----------|
| Producción primaria fitoplanctónica | Biológico | Productividad de poblaciones | Luz + nutrientes → biomasa → red trófica |
| Fotosíntesis de praderas marinas | Biológico | Almacenamiento de carbono | Captación de CO2 → materia orgánica → enterramiento en sedimentos |
| Filtración por bancos de mejillones | Ecológico | Claridad del agua | Alimentación por filtración elimina partículas |

**Consejos:**
- Concéntrese en los procesos relevantes para sus ES
- Use experiencia científica
- Considere las escalas espaciales y temporales
- Múltiples procesos pueden contribuir a un ES

---

### Exercise 3: Especificación de Presiones sobre los Cambios de Estado

**Objetivo:** Identificar los factores de estrés que afectan a los procesos marinos.

**Qué Introducir para Cada Presión:**
- **Nombre:** Nombre claro de la presión
- **Tipo:** Física / Química / Biológica / Múltiple
- **Descripción:** Naturaleza del factor de estrés
- **Vinculado a MPF:** Seleccione del menú desplegable (MPF del Ej. 2b)
- **Intensidad:** Alta / Media / Baja / Desconocida
- **Espacial:** Dónde ocurre
- **Temporal:** Cuándo/con qué frecuencia (continua/estacional/episódica)

**Tipos de Presiones:**
- **Físicas:** Abrasión del fondo marino, pérdida de hábitat, ruido, calor
- **Químicas:** Enriquecimiento de nutrientes, contaminantes, acidificación
- **Biológicas:** Extracción de especies, especies invasoras, patógenos
- **Múltiples:** Efectos combinados

**Cómo Usar:**
1. Haga clic en "Añadir Presión"
2. Complete los campos
3. Seleccione qué MPF afecta esta presión
4. Evalúe la intensidad y describa los patrones espaciales/temporales
5. Haga clic en "Guardar Exercise 3"

**Ejemplos:**

| Nombre de la Presión | Tipo | Vinculado a MPF | Intensidad |
|----------------------|------|-----------------|------------|
| Enriquecimiento de nutrientes | Química | Composición del fitoplancton | Alta |
| Pesca de arrastre de fondo | Física | Estructura del hábitat bentónico | Alta |
| Sobrepesca | Biológica | Dinámica de la red trófica | Media |

**Consejos:**
- Una presión puede afectar a múltiples procesos
- Especifique el mecanismo directo
- Considere los efectos acumulativos
- Incluya tanto presiones crónicas como agudas
- Use evidencia científica para las valoraciones de intensidad

---

### Exercise 4: Especificación de Actividades que Afectan a las Presiones

**Objetivo:** Identificar las actividades humanas que generan presiones.

**Qué Introducir para Cada Actividad:**
- **Nombre:** Nombre claro
- **Sector:** Pesquerías / Acuicultura / Turismo / Navegación / Energía / Minería / Otros
- **Descripción:** En qué consiste la actividad
- **Vinculado a Presión:** Seleccione del menú desplegable (presiones del Ej. 3)
- **Escala:** Local / Regional / Nacional / Internacional
- **Frecuencia:** Continua / Estacional / Ocasional / Puntual

**Actividades Marinas Comunes:**
- **Pesquerías:** Pesca comercial/recreativa/de subsistencia
- **Acuicultura:** Cultivo de peces/moluscos
- **Turismo:** Turismo de playa, observación de fauna, buceo
- **Navegación:** Carga, cruceros, ferris
- **Energía:** Eólica marina, petróleo y gas, mareomotriz/undimotriz
- **Infraestructura:** Puertos, construcción costera
- **Agricultura:** Escorrentía de nutrientes (terrestre pero con impacto marino)

**Cómo Usar:**
1. Haga clic en "Añadir Actividad"
2. Complete los campos
3. Seleccione qué presión(es) genera esta actividad
4. Especifique la escala y frecuencia
5. Haga clic en "Guardar Exercise 4"

**Ejemplos:**

| Nombre de la Actividad | Sector | Vinculado a Presión | Escala |
|------------------------|--------|---------------------|--------|
| Pesca de arrastre de fondo | Pesquerías | Abrasión del fondo marino | Regional |
| Vertido de aguas residuales costeras | Residuos | Enriquecimiento de nutrientes | Local |
| Tráfico marítimo | Navegación | Ruido submarino, contaminación por hidrocarburos | Internacional |

**Consejos:**
- Sea específico: "Arrastre de fondo" no solo "Pesca"
- Una actividad a menudo genera múltiples presiones
- Considere vías directas e indirectas
- Incluya patrones estacionales

---

### Exercise 5: Factores Impulsores que Dan Lugar a Actividades

**Objetivo:** Identificar las fuerzas subyacentes que motivan las actividades.

**Qué Introducir para Cada Factor Impulsor:**
- **Nombre:** Nombre claro
- **Tipo:** Económico / Social / Tecnológico / Político / Ambiental / Demográfico
- **Descripción:** Qué es esta fuerza y cómo funciona
- **Vinculado a Actividad:** Seleccione del menú desplegable (actividades del Ej. 4)
- **Tendencia:** En aumento / Estable / En disminución / Cíclica / Incierta
- **Controlabilidad:** Alta / Media / Baja / Ninguna

**Tipos de Factores Impulsores:**
- **Económicos:** Demanda del mercado, precios, subvenciones, crecimiento económico
- **Sociales:** Tradiciones culturales, preferencias del consumidor, normas sociales
- **Tecnológicos:** Innovación en artes de pesca, eficiencia de embarcaciones, nuevas técnicas
- **Políticos:** Regulaciones, gobernanza, acuerdos internacionales
- **Ambientales:** Cambio climático, fenómenos meteorológicos extremos (como factores de adaptación)
- **Demográficos:** Crecimiento demográfico, urbanización, migración

**Cómo Usar:**
1. Haga clic en "Añadir Factor Impulsor"
2. Complete los campos
3. Seleccione qué actividad(es) motiva este factor
4. Evalúe la tendencia y controlabilidad
5. Haga clic en "Guardar Exercise 5"

**Ejemplos:**

| Nombre del Factor | Tipo | Vinculado a Actividad | Controlabilidad |
|-------------------|------|-----------------------|-----------------|
| Demanda global de productos del mar | Económico | Expansión de la pesca comercial | Baja |
| Objetivos de energía renovable de la UE | Político | Desarrollo eólico marino | Alta |
| Demanda de turismo costero | Social/Económico | Desarrollo costero | Media |

**Consejos:**
- Piense en POR QUÉ las personas se involucran en actividades
- Considere tanto factores de empuje como de atracción
- Los factores impulsores a menudo interactúan (económico + tecnológico + político)
- Evalúe la controlabilidad honestamente
- Los factores impulsores son a menudo los mejores puntos de intervención

---

### Exercise 6: Cerrar el Bucle - Factores Impulsores a Bienes y Beneficios

**Objetivo:** Crear bucles de retroalimentación conectando los factores impulsores de vuelta a los bienes y beneficios.

**Qué Identificar:**
- ¿Cómo influyen los cambios en los Bienes y Beneficios sobre los Factores Impulsores?
- ¿Cómo responden los Factores Impulsores a las condiciones del ecosistema?
- ¿Qué retroalimentaciones son reforzadoras (amplificadoras)?
- ¿Cuáles son equilibradoras (estabilizadoras)?

**Tipos de Bucles de Retroalimentación:**

**Bucles Reforzadores (R):** Los cambios se amplifican a sí mismos
- Ejemplo: Disminución de poblaciones de peces → Menores beneficios → Mayor esfuerzo pesquero para mantener ingresos → Mayor disminución

**Bucles Equilibradores (B):** Los cambios desencadenan respuestas compensatorias
- Ejemplo: Disminución de la calidad del agua → Reducción del turismo → Presión económica para la limpieza → Mejora de la calidad

**Cómo Usar:**
1. Revise la interfaz de conexiones de bucle
2. Seleccione las conexiones factor impulsor-a-G&B que crean retroalimentaciones significativas
3. Documente si las retroalimentaciones son reforzadoras o equilibradoras
4. Haga clic en "Guardar Exercise 6"

**Ejemplos:**

| De (G&B) | A (Factor Impulsor) | Tipo | Explicación |
|----------|---------------------|------|-------------|
| Disminución de la captura de peces | Reducción de la capacidad pesquera | Equilibrador | Los bajos beneficios sacan a los pescadores de la industria |
| Mejora de la calidad del agua | Apoyo político a la conservación | Reforzador | El éxito genera más política de conservación |
| Daños costeros por tormentas | Política de restauración de ecosistemas | Equilibrador | Las pérdidas desencadenan medidas protectoras |

**Consejos:**
- No todos los factores impulsores necesitan conectarse de vuelta
- Considere los desfases temporales (años en manifestarse)
- El conocimiento de las partes interesadas es crucial
- Documente el tipo de bucle (R o B)

---

### Exercises 7-9: Creación y Exportación de Diagramas de Bucle Causal

**Objetivo:** Visualizar la estructura de su sistema en el software Kumu.

#### Exercise 7: Crear CLD Basado en Impacto en Kumu

**Pasos:**
1. Haga clic en "Descargar Archivos CSV de Kumu" para exportar sus datos
2. Vaya a [kumu.io](https://kumu.io) y cree una cuenta gratuita
3. Cree un nuevo proyecto (elija la plantilla "Causal Loop Diagram")
4. Importe sus archivos CSV:
   - `elements.csv` → contiene todos los nodos
   - `connections.csv` → contiene todas las aristas
5. Aplique el código de estilo de Kumu desde `Documents/Kumu_Code_Style.txt`
6. Organice los elementos para mostrar flujos causales claros

**Esquema de Colores de Kumu:**
- Bienes y Beneficios: Triángulos amarillos
- Servicios Ecosistémicos: Cuadrados azules
- Procesos Marinos: Píldoras azul claro
- Presiones: Diamantes naranjas
- Actividades: Hexágonos verdes
- Factores Impulsores: Octágonos morados

#### Exercise 8: De Cadenas de Lógica Causal a Bucles Causales

**Pasos:**
1. En Kumu, identifique los bucles cerrados en su diagrama
2. Trace caminos desde un elemento de vuelta a sí mismo
3. Clasifique los bucles como reforzadores (R) o equilibradores (B)
4. Añada identificadores de bucle en Kumu (use etiquetas o marcadores)
5. Concéntrese en los bucles más importantes que impulsan el comportamiento del sistema

**Identificar el Tipo de Bucle:**
- Cuente el número de vínculos negativos (-) en el bucle
- Número par de vínculos (-) = Reforzador (R)
- Número impar de vínculos (-) = Equilibrador (B)

#### Exercise 9: Exportar CLD para Análisis Posterior

**Pasos:**
1. Exporte imágenes de alta resolución desde Kumu:
   - Haga clic en Compartir → Exportar → PNG/PDF
2. Descargue el libro de trabajo Excel completo desde el módulo ISA
3. Revise las matrices de adyacencia para verificar todas las conexiones
4. Cree diferentes vistas:
   - Vista del sistema completo
   - Vistas de subsistemas (p. ej., solo pesquerías)
   - Vistas de bucles clave
5. Documente los bucles clave con descripciones narrativas

**Haga clic en "Guardar Exercises 7-9" cuando haya terminado.**

---

### Exercises 10-12: Clarificación, Métricas y Validación

#### Exercise 10: Clarificación - Endogenización y Encapsulación

**Endogenización:** Incorporar factores externos dentro del límite del sistema

**Qué Hacer:**
1. Revise los factores impulsores externos
2. ¿Alguno puede explicarse por factores dentro de su sistema?
3. Añada estas retroalimentaciones internas
4. Documente en "Notas de Endogenización"

**Ejemplo:** "Demanda del mercado" podría estar influenciada por la "calidad del producto" dentro de su sistema

**Encapsulación:** Agrupar procesos detallados en conceptos de nivel superior

**Qué Hacer:**
1. Identifique subsistemas excesivamente complejos
2. Agrupe elementos relacionados (p. ej., múltiples procesos de nutrientes → "Dinámica de eutrofización")
3. Mantenga la versión detallada para el trabajo técnico
4. Cree una versión simplificada para la comunicación de políticas
5. Documente en "Notas de Encapsulación"

#### Exercise 11: Métricas, Causas Raíz y Puntos de Apalancamiento

**Análisis de Causas Raíz:**
1. Use la interfaz de "Causas Raíz"
2. Identifique elementos con muchos vínculos salientes
3. Trace hacia atrás desde los problemas hasta las causas últimas
4. Concéntrese en los factores impulsores y actividades

**Identificación de Puntos de Apalancamiento:**
1. Use la interfaz de "Puntos de Apalancamiento"
2. Busque:
   - Puntos de control de bucles
   - Nodos de alta centralidad (muchas conexiones)
   - Puntos de convergencia (múltiples vías se encuentran)
3. Considere la viabilidad y controlabilidad
4. Priorice los puntos de apalancamiento accionables

**Jerarquía de Meadows:**
- Más débil: Parámetros (números, tasas)
- Más fuerte: Bucles de retroalimentación
- Muy fuerte: Diseño/estructura del sistema
- Más fuerte: Paradigmas (mentalidades, objetivos)

#### Exercise 12: Presentación y Validación de Resultados

**Enfoques de Validación:**
- ✓ Revisión interna del equipo
- ✓ Taller con partes interesadas
- ✓ Revisión por pares expertos
- ✓ Aprobación final

**Qué Hacer:**
1. Realice actividades de validación
2. Registre los comentarios en "Notas de Validación"
3. Marque las casillas de los tipos de validación completados
4. Actualice su modelo basándose en los comentarios
5. Prepare presentaciones para diferentes audiencias

**Consejos de Presentación:**
- Adapte la complejidad a la audiencia
- Use el CLD visual para la visión general
- Cuente historias sobre los bucles clave
- Muestre gráficos BOT como evidencia
- Vincule a recomendaciones de políticas
- Sea transparente sobre las incertidumbres

**Haga clic en "Guardar Exercises 10-12" cuando haya terminado.**

---

### Gráficos BOT: Comportamiento a lo Largo del Tiempo {#bot-graphs-behaviour-over-time}

**Objetivo:** Visualizar dinámicas temporales para validar su modelo causal.

**Cómo Crear Gráficos BOT:**

1. **Seleccione el Tipo de Elemento:** Elija del menú desplegable (Bienes y Beneficios / ES / MPF / Presiones / Actividades / Factores Impulsores)
2. **Seleccione el Elemento Específico:** Elija qué elemento graficar
3. **Añada Puntos de Datos:**
   - Año
   - Valor
   - Unidad (p. ej., "toneladas", "%", "índice")
   - Haga clic en "Añadir Punto de Datos"
4. **Ver Gráfico:** La serie temporal aparece automáticamente
5. **Repita** para otros elementos

**Patrones a Buscar:**
- **Tendencias:** Aumento/disminución constante
- **Ciclos:** Oscilaciones regulares
- **Escalones:** Cambios repentinos (cambios de política)
- **Retrasos:** Desfases temporales
- **Umbrales:** Puntos de inflexión
- **Mesetas:** Estabilidad

**Uso de Gráficos BOT:**
- Compare patrones con las predicciones del CLD
- Identifique evidencia de bucles de retroalimentación
- Mida los desfases temporales
- Evalúe las intervenciones políticas
- Proyecte escenarios futuros

**Fuentes de Datos:**
- Estadísticas oficiales
- Monitoreo ambiental
- Encuestas científicas
- Observaciones de partes interesadas
- Registros históricos

**Haga clic en "Guardar Datos BOT" para conservar su trabajo.**

---

## Trabajar con Kumu {#working-with-kumu}

### Primeros Pasos con Kumu

**1. Crear Cuenta:**
- Vaya a [kumu.io](https://kumu.io)
- Regístrese para una cuenta gratuita
- Los proyectos públicos son gratuitos; los privados requieren suscripción

**2. Crear Nuevo Proyecto:**
- Haga clic en "Nuevo Proyecto"
- Elija la plantilla "Causal Loop Diagram"
- Nombre su proyecto

**3. Importar Datos:**
- Desde el módulo ISA, descargue los archivos CSV de Kumu
- En Kumu, haga clic en Importar
- Cargue `elements.csv` y `connections.csv`

### Aplicar Estilos Personalizados

**Copie el Código de Kumu:**
- Abra `Documents/Kumu_Code_Style.txt`
- Copie todo el contenido

**Aplique a Su Mapa:**
1. En Kumu, haga clic en el icono de Configuración
2. Vaya a "Editor Avanzado"
3. Pegue el código
4. Haga clic en "Guardar"

**Resultado:** Sus elementos estarán codificados por colores y formas según el tipo:
- Bienes y Beneficios: Triángulos amarillos
- Servicios Ecosistémicos: Cuadrados azules
- Procesos Marinos: Píldoras azul claro
- Presiones: Diamantes naranjas
- Actividades: Hexágonos verdes
- Factores Impulsores: Octágonos morados

### Trabajar con el Diagrama

**Opciones de Diseño:**
- Diseño automático: Deje que Kumu organice los elementos
- Manual: Arrastre los elementos a las posiciones preferidas
- Circular: Enfatice la estructura de bucles
- Jerárquico: Muestre el flujo causal desde los factores impulsores hasta el bienestar

**Añadir Información:**
- Haga clic en cualquier elemento para editar propiedades
- Añada descripciones, etiquetas, campos personalizados
- Incluya fuentes de datos, niveles de confianza

**Resaltar Bucles:**
1. Identifique un camino de bucle cerrado
2. Añada una etiqueta "Bucle" a todos los elementos del bucle
3. Use el filtro de Kumu para mostrar/ocultar bucles
4. Etiquete los bucles (p. ej., "R1: Espiral de Sobrepesca", "B1: Recuperación de la Calidad")

**Filtros y Vistas:**
- Filtre por tipo de elemento (mostrar solo Factores Impulsores)
- Filtre por importancia, confianza, etc.
- Cree múltiples vistas (sistema completo, bucles clave, subsistemas)
- Guarde las vistas para presentaciones

### Colaboración

**Compartir:**
- Comparta un enlace de solo lectura con las partes interesadas
- Exporte capturas de pantalla para informes
- Integre en sitios web/presentaciones

**Edición en Equipo:**
- Añada colaboradores (función de pago)
- Varias personas pueden editar simultáneamente
- Control de versiones disponible

### Opciones de Exportación

**Desde Kumu:**
- **PNG:** Imagen de alta resolución para informes
- **PDF:** Formato vectorial para publicaciones
- **JSON:** Datos en bruto para archivado
- **Enlace compartido:** Vista web interactiva

**Desde el Módulo ISA:**
- **Libro de trabajo Excel:** Datos completos con todas las hojas
- **CSV de Kumu:** Elementos y conexiones
- **Matrices de adyacencia:** Matrices de conexión para análisis

---

## Gestión de Datos {#data-management}

### Guardar Su Trabajo

**Autoguardado:**
- Los datos se almacenan en el estado reactivo de la aplicación durante su sesión
- Use los botones "Guardar" después de completar cada ejercicio

**Exportar a Excel:**
1. Vaya a la pestaña "Gestión de Datos"
2. Introduzca el nombre del archivo (p. ej., "MiCaso_ISA_2024")
3. Haga clic en "Exportar a Excel"
4. Se descarga el libro de trabajo completo con todos los datos

### Importar Datos Existentes

**Desde Excel:**
1. Vaya a la pestaña "Gestión de Datos"
2. Haga clic en "Elegir Archivo Excel"
3. Seleccione su archivo .xlsx previamente exportado
4. Haga clic en "Importar Datos"
5. Los datos llenan todos los ejercicios

**Estructura del Archivo Excel:**
- Hoja: Case_Info
- Hoja: Goods_Benefits
- Hoja: Ecosystem_Services
- Hoja: Marine_Processes
- Hoja: Pressures
- Hoja: Activities
- Hoja: Drivers
- Hoja: BOT_Data

### Restablecer Datos

**Advertencia:** Esto borra TODOS los datos y no se puede deshacer.

1. Vaya a la pestaña "Gestión de Datos"
2. Haga clic en "Restablecer Todos los Datos" (botón rojo)
3. Confirme la acción
4. Todos los ejercicios vuelven al estado en blanco

**Cuándo Restablecer:**
- Comenzar un estudio de caso completamente nuevo
- Descartar una ejecución de práctica
- Después de exportar los datos que desea conservar

### Flujos de Trabajo Colaborativos

**Trabajo Individual:**
- Una persona introduce todos los datos
- Exportar Excel cuando termine
- Compartir archivo con el equipo para revisión

**Trabajo Secuencial:**
- Persona A: Exercises 0-3 → Exportar
- Persona B: Importar → Exercises 4-6 → Exportar
- Persona C: Importar → Exercises 7-12 → Exportación final

**Trabajo Paralelo:**
- Varias personas trabajan en diferentes ejercicios en sesiones separadas
- Consolidar en Excel (fusionar hojas manualmente)
- Importar archivo consolidado

**Basado en Talleres:**
- Facilitar discusiones grupales para cada ejercicio
- Una persona opera la herramienta e introduce datos de consenso
- Exportar después de cada ejercicio para registro

---

## Consejos y Mejores Prácticas {#tips-and-best-practices}

### Consejos Generales de Flujo de Trabajo

**1. Trabaje sistemáticamente:**
- Complete los ejercicios en orden
- No se adelante (los ejercicios posteriores se basan en los anteriores)
- Guarde después de cada ejercicio

**2. Involucre a las partes interesadas:**
- Realice talleres para los Exercises 1-6
- Valide el CLD con quienes conocen el sistema
- Use perspectivas diversas (usuarios, gestores, científicos)

**3. Use evidencia científica:**
- Base los vínculos en estudios revisados por pares
- Cite fuentes en las descripciones
- Anote niveles de confianza

**4. Comience simple, añada detalle:**
- Primera pasada: Solo elementos principales
- Segunda pasada: Añada matices y detalles
- Mantenga una versión simplificada para comunicación

**5. Documente todo:**
- Use los campos de descripción generosamente
- Registre las fuentes de datos
- Anote suposiciones e incertidumbres

### Consejos de Calidad de Datos

**Sea Específico:**
- ❌ "Pesca" → ✅ "Pesca comercial de arrastre de fondo para especies demersales"
- ❌ "Contaminación" → ✅ "Enriquecimiento de nutrientes por escorrentía agrícola"

**Sea Completo:**
- Incluya impactos positivos y negativos
- Considere todos los grupos de partes interesadas
- Cubra todos los sectores que usan el área marina

**Sea Realista:**
- Concéntrese en los elementos importantes (80% superior)
- No intente incluirlo todo
- La complejidad debe coincidir con el conocimiento disponible

**Sea Consistente:**
- Use terminología consistente
- Mantenga un nivel de detalle consistente en todos los ejercicios
- Siga las convenciones de nomenclatura (p. ej., IDs de elementos)

### Consejos para el Desarrollo del CLD

**Diseño:**
- Organice en flujo causal: Factores Impulsores → Actividades → Presiones → Estado → Bienestar
- Coloque los bucles de retroalimentación de forma prominente
- Minimice los cruces de aristas para legibilidad

**Bucles:**
- Identifique y etiquete los bucles clave (R1, R2, B1, B2)
- Concéntrese en los bucles que impulsan el comportamiento problemático
- Documente las narrativas de los bucles (¿qué historia cuenta cada bucle?)

**Validación:**
- ¿El CLD explica el comportamiento observado del sistema?
- ¿Las partes interesadas reconocen la estructura?
- ¿Puede rastrear eventos históricos específicos a través del diagrama?

### Consejos para Gráficos BOT

**Recopilación de Datos:**
- Use las series temporales más largas disponibles
- Sea consistente con unidades y escalas
- Documente las fuentes de datos claramente

**Comparación:**
- Grafique variables relacionadas en el mismo eje temporal
- Busque correlaciones (¿coinciden con su CLD?)
- Identifique desfases temporales entre causa y efecto

**Comunicación:**
- Anote con eventos clave (cambios de política, desastres)
- Use esquemas de colores consistentes
- Incluya barras de error o rangos de incertidumbre si están disponibles

### Errores Comunes a Evitar

**1. Demasiado detalle demasiado pronto:**
- Comience con los elementos principales
- Añada detalle en iteraciones
- Mantenga una versión simplificada

**2. Omitir la aportación de las partes interesadas:**
- El conocimiento local es invaluable
- La legitimidad requiere participación
- Los puntos ciegos emergen sin perspectivas diversas

**3. Confundir ES y G&B:**
- ES = capacidad/potencial del ecosistema
- G&B = beneficios realizados que las personas obtienen
- Ejemplo: "Población de peces" (ES) vs. "Captura de peces" (G&B)

**4. Vínculos débiles:**
- Siempre especifique el mecanismo
- Evite conexiones vagas
- Prueba: ¿Puede explicar este vínculo a una parte interesada?

**5. Ignorar el tiempo:**
- Los retrasos son cruciales
- Algunos efectos tardan años en manifestarse
- Los gráficos BOT revelan patrones temporales

**6. Sin bucles de retroalimentación:**
- El Exercise 6 es crítico
- Los sistemas son circulares, no lineales
- Las retroalimentaciones impulsan la dinámica

**7. Omitir la validación:**
- Su modelo es una hipótesis
- Pruébelo contra datos y conocimiento de partes interesadas
- Itere basándose en los comentarios

---

## Resolución de Problemas {#troubleshooting}

### Problemas Comunes y Soluciones

**Problema: "Mis datos no se guardaron"**
- **Solución:** Siempre haga clic en el botón "Guardar Exercise X" después de introducir datos
- Verifique que la tabla de datos se actualice después de guardar
- Exporte a Excel frecuentemente como respaldo

**Problema: "Las listas desplegables están vacías"**
- **Causa:** No ha completado el ejercicio anterior
- **Solución:** Complete los ejercicios en orden. El Ej. 2a necesita datos del Ej. 1, etc.

**Problema: "Cometí un error en un ejercicio anterior"**
- **Solución:** Vuelva a la pestaña de ese ejercicio
- Los datos siguen ahí y son editables
- Haga correcciones y haga clic en Guardar de nuevo

**Problema: "La exportación a Excel no funciona"**
- **Verifique:** La configuración de descargas del navegador
- **Verifique:** Los permisos de archivo en la carpeta de descargas
- **Intente:** Un navegador diferente

**Problema: "La importación a Kumu falla"**
- **Verifique:** El formato del archivo CSV (debe ser separado por comas)
- **Verifique:** Que los encabezados de columna coincidan con las expectativas de Kumu
- **Intente:** Importar elementos primero, luego conexiones

**Problema: "La aplicación es lenta con conjuntos de datos grandes"**
- **Normal:** Más de 100 elementos pueden ralentizar el renderizado
- **Solución:** Trabaje en subsistemas por separado
- **Solución:** Use Excel para gestión de datos, la aplicación para estructura

**Problema: "No puedo encontrar el contenido de ayuda"**
- **Ubicación:** Haga clic en el botón de Ayuda "?" en cada pestaña de ejercicio
- **Guía principal:** Haga clic en "Guía del Marco ISA" en la parte superior del módulo

### Obtener Ayuda Adicional

**Documentación:**
- Esta Guía del Usuario
- Guía de Orientación BORRADOR de SES Simple de MarineSABRES (carpeta Documentos)
- Documentación de Kumu: [docs.kumu.io](https://docs.kumu.io)

**Soporte Técnico:**
- Verifique la versión de la aplicación y la compatibilidad del navegador
- Contacte al equipo del proyecto MarineSABRES
- Reporte errores a través de GitHub (si corresponde)

**Soporte Científico:**
- Consulte el documento de orientación para preguntas metodológicas
- Involucre a expertos del dominio para su estudio de caso específico
- Participe en talleres de formación ISA

---

## Glosario {#glossary}

**Actividades (A):** Usos humanos de los ambientes marinos y costeros (pesca, navegación, turismo, etc.)

**Matriz de Adyacencia:** Tabla que muestra qué elementos están conectados con qué otros elementos

**Bucle Equilibrador (B):** Bucle de retroalimentación que contrarresta el cambio y estabiliza el sistema

**Gráfico BOT (Comportamiento a lo Largo del Tiempo):** Gráfico de series temporales que muestra cómo cambia un indicador a lo largo del tiempo

**Cadena Causal:** Secuencia lineal de relaciones causa-efecto (p. ej., Factores Impulsores → Actividades → Presiones)

**Diagrama de Bucle Causal (CLD):** Red visual que muestra elementos y sus relaciones causales, incluyendo bucles de retroalimentación

**DAPSI(W)R(M):** Marco de Factores Impulsores-Actividades-Presiones-Estado(Bienestar)-Respuestas(Medidas)

**Factores Impulsores (D):** Fuerzas subyacentes que motivan las actividades (económicas, sociales, políticas, tecnológicas)

**Servicios Ecosistémicos (ES):** La capacidad de los ecosistemas para generar beneficios para las personas

**Encapsulación:** Agrupación de elementos detallados en conceptos de nivel superior para simplificación

**Endogenización:** Incorporar factores externos dentro del límite del sistema añadiendo retroalimentaciones internas

**Bucle de Retroalimentación:** Vía causal circular donde un elemento se influye a sí mismo a través de una cadena de otros elementos

**Bienes y Beneficios (G&B):** Beneficios realizados que las personas obtienen de los ecosistemas marinos (impactos en el bienestar)

**ISA (Análisis Integrado de Sistemas):** Marco sistemático para analizar sistemas socioecológicos

**Kumu:** Software gratuito de visualización de redes en línea (kumu.io)

**Punto de Apalancamiento:** Ubicación en el sistema donde una pequeña intervención puede producir un gran cambio

**Procesos y Funcionamiento Marino (MPF):** Procesos biológicos, químicos, físicos y ecológicos que sustentan los servicios ecosistémicos

**Medidas (M):** Intervenciones políticas y acciones de gestión (respuestas)

**Polaridad:** Dirección de la influencia causal (+ misma dirección, - dirección opuesta)

**Presiones (P):** Factores de estrés directos sobre el medio ambiente marino (contaminación, destrucción de hábitat, extracción de especies)

**Bucle Reforzador (R):** Bucle de retroalimentación que amplifica el cambio (puede ser un ciclo virtuoso o vicioso)

**Respuestas (R):** Acciones de la sociedad para abordar los problemas

**Causa Raíz:** Factor impulsor o actividad fundamental en el origen de una cadena causal

**Sistema Socioecológico (SES):** Sistema integrado de personas y naturaleza, con retroalimentaciones recíprocas

**Cambios de Estado (S):** Cambios en la condición del ecosistema (representados a través de W, ES y MPF)

**Bienestar (W):** Bienestar humano, representado a través de bienes y beneficios de los ecosistemas

---

## Apéndice: Tarjeta de Referencia Rápida {#appendix-quick-reference-card}

### Lista de Verificación de Ejercicios

- [ ] Exercise 0: Definir el alcance del estudio de caso
- [ ] Exercise 1: Enumerar todos los Bienes y Beneficios
- [ ] Exercise 2a: Identificar Servicios Ecosistémicos
- [ ] Exercise 2b: Identificar Procesos y Funcionamiento Marino
- [ ] Exercise 3: Identificar Presiones
- [ ] Exercise 4: Identificar Actividades
- [ ] Exercise 5: Identificar Factores Impulsores
- [ ] Exercise 6: Cerrar los bucles de retroalimentación
- [ ] Exercise 7: Crear CLD en Kumu
- [ ] Exercise 8: Identificar bucles causales
- [ ] Exercise 9: Exportar y documentar CLD
- [ ] Exercise 10: Clarificar el modelo (endogenización, encapsulación)
- [ ] Exercise 11: Identificar puntos de apalancamiento
- [ ] Exercise 12: Validar con las partes interesadas
- [ ] Gráficos BOT: Añadir datos temporales
- [ ] Exportar libro de trabajo Excel final

### Atajos de Teclado

- **Tab:** Moverse entre campos del formulario
- **Enter:** Enviar/Guardar formulario
- **Ctrl+F / Cmd+F:** Buscar dentro de las tablas

### Ubicaciones de Archivos

- **Guía del Usuario:** `Documents/ISA_User_Guide.md`
- **Documento de Orientación:** `Documents/MarineSABRES_Simple_SES_DRAFT_Guidance.pdf`
- **Estilos de Kumu:** `Documents/Kumu_Code_Style.txt`
- **Plantilla Excel:** `Documents/ISA Excel Workbook.xlsx`

### Enlaces Útiles

- **Kumu:** [https://kumu.io](https://kumu.io)
- **Documentación de Kumu:** [https://docs.kumu.io](https://docs.kumu.io)
- **Marco DAPSI(W)R:** Elliott et al. (2017), Marine Pollution Bulletin

---

## Información del Documento {#document-information}

**Documento:** Módulo de Entrada de Datos ISA - Guía del Usuario
**Proyecto:** Caja de Herramientas de Sistemas Socioecológicos MarineSABRES
**Version:** 1.0
**Fecha:** Abril 2026
**Estado:** Borrador (traducción automática)

**Cita:**
> Proyecto MarineSABRES (2025). Módulo de Entrada de Datos ISA - Guía del Usuario.
> Herramienta de Análisis de Sistemas Socioecológicos MarineSABRES, Versión 1.0.

**Licencia:** Esta guía se proporciona para uso con la Caja de Herramientas SES de MarineSABRES.

---

**Para preguntas, comentarios o soporte, contacte al equipo del proyecto MarineSABRES.**

**¡Buen análisis!**
