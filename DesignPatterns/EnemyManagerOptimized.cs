using UnityEngine;
using System.Collections.Generic;

public class EnemyManagerOptimized : Singleton<EnemyManagerOptimized>
{
    //http://www.dofactory.com/net/design-patterns
    //https://github.com/Naphier/unity-design-patterns

    //FIELDS
    public GameObject _prefabEnemy = null;
    private MemoryPool<EnemyBehaviourExtended> _pool = new MemoryPool<EnemyBehaviourExtended>(10);
    private int _amountOfEnemies = 100000;
    private float _spawnTimer = 0.0f;
    private float _spawnRatio = 0.1f;
    private int _counter = 0;

    //METHODS
    // Use this for initialization
    void Start()
    {
        //Fill pool
        _pool.FillPool(_prefabEnemy);
        _spawnTimer = _spawnRatio;
    }

    // Update is called once per frame
    void Update()
    {
        //Spawn enemies
        if (_counter < _amountOfEnemies)
        {
            _spawnTimer -= Time.deltaTime;
            if (_spawnTimer <= 0)
            {
                _spawnTimer = _spawnRatio;
                //Spawn objects
                _pool.SpawnObject();
                ++_counter;
            }
        }
    }
    public void RemoveEnemy(EnemyBehaviourExtended enemy)
    {
        _pool.RemoveObject(enemy);
    }
}
