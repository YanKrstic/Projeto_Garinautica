extends Control

@onready var campo_nome = %CampoNome
@onready var http_requisicao = %HTTPRequisicao

# Dados extraídos do seu app.js!
var supabase_url = "https://zjphbjtjdvlouglunwet.supabase.co/rest/v1/partidas"
var supabase_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqcGhianRqZHZsb3VnbHVud2V0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MzcyMjUsImV4cCI6MjA5NzIxMzIyNX0.8WupvEj63DWtcXW0ju9XX_NcQkhxq3gHGOYXKo4UmbY"

func _ready():
	hide()
	http_requisicao.request_completed.connect(_on_requisicao_completada)

func exibir():
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	
	# --- A MÁGICA DA LIMPEZA ---
	# Como a tela é imortal, nós restauramos as configurações dela ao abrir!
	campo_nome.text = "" # Apaga o nome que o jogador digitou na partida passada
	
	if %BotaoEnviar:
		%BotaoEnviar.disabled = false
		%BotaoEnviar.text = "Enviar Tempo para o Dashboard" # (Ou o texto original que você preferir)

func _on_button_pressed():
	var nome_jogador = campo_nome.text.strip_edges()
	if nome_jogador == "":
		print("Erro: Digite um nome de Capitão!")
		return
		
	# Desativa o botão para o jogador não enviar 2 vezes seguidas
	%BotaoEnviar.disabled = true 
	%BotaoEnviar.text = "Enviando..."
		
	# 1. Preparar os Cabeçalhos (O "Crachá" do Supabase)
	var cabecalhos = [
		"Content-Type: application/json",
		"apikey: " + supabase_key,
		"Authorization: Bearer " + supabase_key,
		"Prefer: return=minimal" # Diz ao Supabase para não devolver a tabela toda após salvar
	]
	
	# 2. Montar o JSON com os dados REAIS do jogo
	# (Estou a assumir que você tem estas variáveis no SistemaOxigenio)
	var dados = {
		"nome_jogador": nome_jogador,
		
		# snapped() arredonda o tempo (ex: de 452.1843 para 452.2) para ficar limpo na API!
		"tempo_total_segundos": snapped(SistemaOxigenio.tempo_total_jogado, 0.1), 
		
		# Pega a contagem exata de tudo o que foi reciclado no jogo inteiro
		"lixos_reciclados": SistemaOxigenio.total_lixo_reciclado, 
		
		"data_partida": Time.get_date_string_from_system() 
	}
	
	var json_dados = JSON.stringify(dados)
	
	# 3. Disparar o Foguete!
	var erro = http_requisicao.request(supabase_url, cabecalhos, HTTPClient.METHOD_POST, json_dados)
	
	if erro != OK:
		print("Erro na Godot ao tentar criar a requisição.")
		_restaurar_botao()

func _on_requisicao_completada(resultado, codigo_resposta, cabecalhos, corpo):
	if codigo_resposta == 201: # 201 no Supabase significa "Criado com Sucesso"
		print("SUCESSO! Dados salvos no fundo do mar!")
		# Abre o Vercel no navegador do jogador para ele ver a pontuação dele!
		OS.shell_open("https://garinautica.vercel.app") 
		SistemaOxigenio.reiniciar_partida_completa() # Reinicia o jogo
	else:
		var mensagem_erro = corpo.get_string_from_utf8()
		print("Falha na API (Código ", codigo_resposta, "): ", mensagem_erro)
		_restaurar_botao()

func _restaurar_botao():
	%BotaoEnviar.disabled = false
	%BotaoEnviar.text = "Tentar Novamente"
