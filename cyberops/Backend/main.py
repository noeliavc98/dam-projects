import os
import firebase_admin
from firebase_admin import credentials, firestore
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# ── Ruta relativa al JSON de credenciales ──────────────────────────────────
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CRED_PATH = os.path.join(BASE_DIR, "Credenciales.json")

# ── Inicializar Firebase solo si no está ya inicializado ───────────────────
if not firebase_admin._apps:
    cred = credentials.Certificate(CRED_PATH)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ── Crear la app FastAPI ───────────────────────────────────────────────────
app = FastAPI(
    title="Cyber Ops API",
    description="Backend del juego Cyber Ops",
    version="1.0.0",
)

# ── CORS ───────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Endpoint raíz ──────────────────────────────────────────────────────────
@app.get("/")
def root():
    return {
        "status": "online",
        "mensaje": "Cyber Ops API funcionando correctamente",
        "version": "1.0.0",
    }

# ── Endpoint de salud ──────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok"}
from pydantic import BaseModel
from typing import Optional
import random

# ── MODELOS ────────────────────────────────────────────────────────────────────
class RespuestaRequest(BaseModel):
    usuario_id: str
    nivel: int
    mision: int
    respuesta: str

class PuntuacionRequest(BaseModel):
    usuario_id: str
    puntos: int
    nivel: int

# ── PREGUNTAS DEL NIVEL 1 — RECONOCIMIENTO ─────────────────────────────────────
# Las guardamos aquí de momento, luego las pasamos a Firestore
PREGUNTAS_NIVEL_1 = [
    {
        "id": "n1_m1_q1",
        "mision": 1,
        "pregunta": "¿Qué herramienta se usa para escanear puertos abiertos en una red?",
        "opciones": ["Wireshark", "Nmap", "Metasploit", "Burp Suite"],
        "correcta": "Nmap",
        "explicacion": "Nmap (Network Mapper) es la herramienta estándar para descubrir hosts y servicios en una red.",
        "puntos": 100,
    },
    {
        "id": "n1_m1_q2",
        "mision": 1,
        "pregunta": "¿Qué significa el acrónimo OSINT?",
        "opciones": [
            "Open Source Intelligence",
            "Online Security Internet Tool",
            "Operative System Internal Network",
            "Open System Intrusion Network",
        ],
        "correcta": "Open Source Intelligence",
        "explicacion": "OSINT es la recopilación de información de fuentes públicas y abiertas.",
        "puntos": 100,
    },
    {
        "id": "n1_m2_q1",
        "mision": 2,
        "pregunta": "¿Cuál de estos es un puerto usado por defecto para HTTPS?",
        "opciones": ["80", "21", "443", "22"],
        "correcta": "443",
        "explicacion": "El puerto 443 es el estándar para HTTPS (HTTP seguro con SSL/TLS).",
        "puntos": 150,
    },
    {
        "id": "n1_m2_q2",
        "mision": 2,
        "pregunta": "¿Qué tipo de reconocimiento NO interactúa directamente con el objetivo?",
        "opciones": [
            "Reconocimiento activo",
            "Reconocimiento pasivo",
            "Escaneo de puertos",
            "Fingerprinting",
        ],
        "correcta": "Reconocimiento pasivo",
        "explicacion": "El reconocimiento pasivo recopila información sin contactar al objetivo, usando fuentes públicas.",
        "puntos": 150,
    },
    {
        "id": "n1_m3_q1",
        "mision": 3,
        "pregunta": "¿Qué comando de Linux muestra las conexiones de red activas?",
        "opciones": ["ifconfig", "netstat", "ping", "traceroute"],
        "correcta": "netstat",
        "explicacion": "netstat muestra las conexiones de red, tablas de enrutamiento y estadísticas de interfaz.",
        "puntos": 200,
    },
    {
        "id": "n1_m3_q2",
        "mision": 3,
        "pregunta": "¿Qué es un 'banner grabbing'?",
        "opciones": [
            "Robar el logo de una web",
            "Obtener información de servicios mediante sus mensajes de bienvenida",
            "Capturar paquetes de red",
            "Escanear vulnerabilidades en aplicaciones web",
        ],
        "correcta": "Obtener información de servicios mediante sus mensajes de bienvenida",
        "explicacion": "Banner grabbing consiste en conectarse a un servicio para leer su mensaje de bienvenida y obtener info de la versión.",
        "puntos": 200,
    },
    {
        "id": "n1_m4_q1",
        "mision": 4,
        "pregunta": "¿Qué protocolo usa el comando ping?",
        "opciones": ["TCP", "UDP", "ICMP", "FTP"],
        "correcta": "ICMP",
        "explicacion": "El ping usa el protocolo ICMP (Internet Control Message Protocol) para comprobar la conectividad.",
        "puntos": 250,
    },
    {
        "id": "n1_m4_q2",
        "mision": 4,
        "pregunta": "¿Qué es un 'footprint' en ciberseguridad?",
        "opciones": [
            "La huella digital de un archivo",
            "La recopilación de información sobre un objetivo antes de atacar",
            "Un tipo de malware",
            "Una técnica de cifrado",
        ],
        "correcta": "La recopilación de información sobre un objetivo antes de atacar",
        "explicacion": "Footprinting es la primera fase de un ataque: recopilar toda la información posible del objetivo.",
        "puntos": 250,
    },
    {
        "id": "n1_m5_q1",
        "mision": 5,
        "pregunta": "¿Qué herramienta permite analizar el tráfico de red en tiempo real?",
        "opciones": ["Nmap", "John the Ripper", "Wireshark", "Hydra"],
        "correcta": "Wireshark",
        "explicacion": "Wireshark es el analizador de protocolos de red más usado, captura y analiza tráfico en tiempo real.",
        "puntos": 300,
    },
    {
        "id": "n1_m5_q2",
        "mision": 5,
        "pregunta": "¿Qué significa TTL en una respuesta ping?",
        "opciones": [
            "Time To Live",
            "Total Transfer Length",
            "Terminal Transfer Layer",
            "Tunnel Transport Link",
        ],
        "correcta": "Time To Live",
        "explicacion": "TTL indica cuántos saltos puede hacer un paquete antes de ser descartado. Ayuda a identificar el SO del objetivo.",
        "puntos": 300,
    },
]

# ── ENDPOINT: obtener preguntas de una misión ──────────────────────────────────
@app.get("/nivel/{nivel}/mision/{mision}/preguntas")
def obtener_preguntas(nivel: int, mision: int):
    if nivel == 1:
        preguntas = [p for p in PREGUNTAS_NIVEL_1 if p["mision"] == mision]
        if not preguntas:
            return {"error": "Misión no encontrada"}
        # Mezclamos las opciones para que no siempre estén en el mismo orden
        for p in preguntas:
            random.shuffle(p["opciones"])
        return {"nivel": nivel, "mision": mision, "preguntas": preguntas}
    return {"error": "Nivel no disponible todavía"}

# ── ENDPOINT: validar respuesta ────────────────────────────────────────────────
@app.post("/respuesta/validar")
def validar_respuesta(req: RespuestaRequest):
    # Buscamos la pregunta en el nivel correspondiente
    if req.nivel == 1:
        preguntas = [p for p in PREGUNTAS_NIVEL_1 if p["mision"] == req.mision]
        for pregunta in preguntas:
            if pregunta["correcta"].lower() == req.respuesta.lower():
                return {
                    "correcto": True,
                    "puntos": pregunta["puntos"],
                    "explicacion": pregunta["explicacion"],
                }
        return {
            "correcto": False,
            "puntos": 0,
            "explicacion": "Respuesta incorrecta. Sigue intentándolo, agente.",
        }
    return {"error": "Nivel no disponible"}

# ── ENDPOINT: guardar puntuación en Firestore ──────────────────────────────────
@app.post("/puntuacion/guardar")
async def guardar_puntuacion(req: PuntuacionRequest):
    try:
        user_ref = db.collection("users").document(req.usuario_id)
        user_doc = user_ref.get()

        if user_doc.exists:
            datos = user_doc.to_dict()
            puntuacion_actual = datos.get("puntuacion_total", 0)
            partidas_jugadas = datos.get("partidas_jugadas", 0)

            user_ref.update({
                "puntuacion_total": puntuacion_actual + req.puntos,
                "partidas_jugadas": partidas_jugadas + 1,
                "nivel": req.nivel + 1,  # desbloquea el siguiente nivel
            })

            return {
                "status": "ok",
                "puntuacion_total": puntuacion_actual + req.puntos,
                "nivel_desbloqueado": req.nivel + 1,
            }
        else:
            return {"error": "Usuario no encontrado en Firestore"}

    except Exception as e:
        return {"error": str(e)}

# ── ENDPOINT: obtener perfil del usuario ───────────────────────────────────────
@app.get("/usuario/{usuario_id}")
async def obtener_usuario(usuario_id: str):
    try:
        doc = db.collection("users").document(usuario_id).get()
        if doc.exists:
            return {"status": "ok", "datos": doc.to_dict()}
        return {"error": "Usuario no encontrado"}
    except Exception as e:
        return {"error": str(e)}