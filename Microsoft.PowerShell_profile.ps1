$env:TERM="xterm-256color"
$env:VIRTUAL_ENV_DISABLE_PROMPT=1
$MYVIMRC="$HOME\AppData\Local\nvim\init.lua"
#Import-Module -Name Terminal-Icons

#oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/takuya.omp.json" | Invoke-Expression
oh-my-posh init pwsh --config $(echo $PROFILE | Split-Path | Join-Path -ChildPath ".mytheme.omp.json") | Invoke-Expression

function virtualenv-Activate
{
	& "./.venv/Scripts/Activate.ps1"
}

function virtualenv-Create
{
	& "virtualenv .venv"
}

function nvir
{
	#https://neovim.io/doc/user/remote.html
	$pipelist = ([System.IO.Directory]::GetFiles("\\.\\pipe\\") | where {$_ -like "*nvim*"})
	if(!$pipelist)
	{
		write-error "No neovim instance found"
		return
	}
	nvim --server $pipelist --remote-tab $($args | gi)
}
