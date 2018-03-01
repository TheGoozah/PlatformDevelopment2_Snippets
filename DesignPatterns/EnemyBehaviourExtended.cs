using System;
using UnityEngine;
using System.Collections.Generic;
using Random = UnityEngine.Random;

public class EnemyBehaviourExtended : MonoBehaviour, PoolableObject
{
    //INTERFACE
    public bool Available { get; set; }

    //FIELDS
    private Vector3 _initialPosition = Vector3.zero;
    private Quaternion _initialRotation = Quaternion.identity;
    private Vector3 _moveVector = Vector3.zero;
    private float _speed = 2.0f;
    private float _rotationSpeed = 2.0f;
    private float _deathTimer = 0.0f;
    private float _timeToDie = 1.0f;

    //BEHAVIOURS
    private Dictionary<Type, IBaseDecorator> _decorators = new Dictionary<Type, IBaseDecorator>();

    //METHODS
    public void Activate() //Change name to spawn because this will be our spawn method!!
    {
        //Random direction
        Vector2 randomDirection = Random.insideUnitCircle;
        _moveVector = new Vector3(randomDirection.x, 0, randomDirection.y).normalized;

        //Set variables
        _deathTimer = _timeToDie;

        //Make this object active
        this.gameObject.SetActive(true);
    }

    public void Deactivate()
    {
        //Make this object inactive
        this.gameObject.SetActive(false);
        //Reset to initial values
        this.transform.position = _initialPosition;
        this.transform.rotation = _initialRotation;
    }

    void Awake() //Before the OnEnable
    {
        //Initial Data
        _initialPosition = this.transform.position;
        _initialRotation = this.transform.rotation;
        //Add decorators
        _decorators.Add(typeof(MoveDecorator), new MoveDecorator());
        //Random add rotation
        if (Random.Range(0, 2) != 0)
        {
            _decorators.Add(typeof(RotateDecorator), new RotateDecorator());
        }
    }

    void Update()
    {
        //Decorators
        foreach (var v in _decorators)
        {
            if(v.Key == typeof(MoveDecorator))
                v.Value.ExecuteBehaviour(new object[] { _moveVector, _speed, Time.deltaTime, this.transform });
            else if(v.Key == typeof(RotateDecorator))
                v.Value.ExecuteBehaviour(new object[] {Vector3.up, _rotationSpeed, this.transform});
        }

        //Destroy after x amount of seconds
        _deathTimer -= Time.deltaTime;
        if (_deathTimer <= 0)
        {
            _deathTimer = 0.0f;
            EnemyManagerOptimized.Instance.RemoveEnemy(this);
        }
    }
}