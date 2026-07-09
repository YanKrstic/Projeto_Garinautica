extends Control

@onready var campo_nome = %CampoNome
@onready var http_requisicao = %HTTPRequisicao

# Substitua por um link temporário ou o link real quando o seu amigo criar!
var url_da_api = "https://sua-api-aqui.vercel.app/api/pontuacao"

func _ready():
	hide()
	# Conecta o sinal do nó HTTP para saber quando o site respondeu
	http_requisicao.request_completed.connect(_on_requisicao_completada)

func exibir():
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true

func _on_button_pressed():
	# 1. Validação simples
	var nome_jogador = campo_nome.text.strip_edges()
	if nome_jogador == "":
		print("Erro: Digite um nome antes de enviar!")
		return
		
	print("Conectando aos servidores da superfície...")
	
	# 2. Montar os dados (O seu amigo dita os nomes destas chaves!)
	var dados_para_enviar = {
		"nome": nome_jogador,
		"fase_alcancada": SistemaOxigenio.fase_atual,
		# "tempo": SistemaOxigenio.tempo_decorrido # (Se formos enviar o tempo depois!)
	}
	
	# 3. Preparar o pacote (Converter para JSON)
	var json_dados = JSON.stringify(dados_para_enviar)
	var cabecalhos = ["Content-Type: application/json"]
	
	# 4. Disparar a requisição POST para a URL
	var erro = http_requisicao.request(url_da_api, cabecalhos, HTTPClient.METHOD_POST, json_dados)
	
	if erro != OK:
		print("Erro interno ao tentar fazer a requisição HTTP.")

# Função que a Godot roda sozinha assim que o Vercel devolver uma resposta
func _on_requisicao_completada(resultado, codigo_resposta, cabecalhos, corpo):
	if codigo_resposta == 200 or codigo_resposta == 201:
		print("Sucesso! Os dados foram salvos no Dashboard!")
		# Aqui você pode mudar a tela, abrir o link do site, etc.
		OS.shell_open("https://link-do-seu-dashboard.com") # Abre o site no PC do jogador!
	else:
		print("Falha na comunicação com a API. Código de erro: ", codigo_resposta)
