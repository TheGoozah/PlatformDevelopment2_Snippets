using UnityEngine;
using System.Collections.Generic;

public interface IBaseDecorator
{
    void ExecuteBehaviour(object[] args);
}

public struct MoveData
{
    public Vector3 Direction;
    public float Speed;
    public float DeltaTime;
    public Transform TransformReference;

    public MoveData(object[] args)
    {
        Direction = (Vector3)args[0];
        Speed = (float)args[1];
        DeltaTime = (float)args[2];
        TransformReference = (Transform)args[3];
    }
}

public struct RotationData
{
    public Vector3 Axis;
    public float Speed;
    public Transform TransformReference;

    public RotationData(object[] args)
    {
        Axis = (Vector3)args[0];
        Speed = (float)args[1];
        TransformReference = (Transform)args[2];
    }
}
public class MoveDecorator : IBaseDecorator
{
    public void ExecuteBehaviour(object[] args)
    {
        //Move unit based on direction and speed
        MoveData a = new MoveData(args);
        //Move
        a.TransformReference.position = a.TransformReference.position + a.Direction * a.Speed * a.DeltaTime;
    }
}

public class RotateDecorator : IBaseDecorator
{
    public void ExecuteBehaviour(object[] args)
    {
        //Rotation data
        RotationData a = new RotationData(args);
        //Move
        a.TransformReference.Rotate(a.Axis, a.Speed);
    }
}