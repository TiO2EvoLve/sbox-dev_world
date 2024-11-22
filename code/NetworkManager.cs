using System;
using System.Numerics;
using System.Threading.Tasks;
using Sandbox;
using Sandbox.Network;
using Sandbox.UI;

public sealed class NetworkManager : Component,Component.INetworkListener
{
	[Property] public GameObject PlayerPrefab { get; set; }
	[Property] public GameObject SpawnPoint { get; set; }
	[Property] public GameObject MessageUI{ get; set; }

	private GameMessage _GameMessage =>MessageUI.Components.Get<GameMessage>(  );

	
	protected override void OnStart()
	{
		//
		// Create a lobby if we're not connected
		//
		if ( !GameNetworkSystem.IsActive )
		{
			GameNetworkSystem.CreateLobby();
		}
		
	}
	
	public void OnActive( Connection channel )
	{
		

		var player = PlayerPrefab.Clone( SpawnPoint.Transform.World  );

		player.NetworkSpawn( channel );
	}

	public void OnConnected( Connection conn )
	{
		_GameMessage.Message = conn.DisplayName +  "Join the Game !";
		MessageUI.Enabled = true;
	}

	public void OnDisconnected( Connection conn )
	{
		_GameMessage.Message = conn.DisplayName +"Leave the Game !";
		MessageUI.Enabled = true;
	}

	
}
