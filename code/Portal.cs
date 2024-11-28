

using Sandbox;

public sealed class Portal : Component,Component.ITriggerListener
{
	[Property] public GameObject target;

	public void OnTriggerEnter(Collider other)
	{
		
		GameTags tag = other.GameObject.Tags;

		if ( tag.Has( "player" ) )
		{
			other.GameObject.Root.WorldPosition = target.WorldPosition;
		}
		
	
	}
	
	
	public void OnTriggerExit(Collider other)
	{
		
	}
}
