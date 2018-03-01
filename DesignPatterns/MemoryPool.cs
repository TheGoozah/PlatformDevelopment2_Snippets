using System;
using UnityEngine;
using System.Collections.Generic;

public interface PoolableObject
{
    bool Available { get; set; }
    void Activate();
    void Deactivate();
}

public class MemoryPool<T> : MonoBehaviour where T : MonoBehaviour, PoolableObject
{
    //FIELDS
    private List<T> _objects;
    private int _capacity = 0;
    private int _activeObjects = 0;

    //METHODS
    public MemoryPool(int capacity) //Constructor
    {
        //Store info
        _capacity = capacity;
        //Create pool with capacity
        _objects = new List<T>(capacity);
    }

    public void FillPool(GameObject o)
    {
        //Fill with objects
        for (int i = 0; i < _capacity; ++i)
        {
            GameObject obj = Instantiate(o);
            T comp = obj.GetComponent<T>();
            comp.Deactivate();
            comp.Available = true;
            _objects.Add(comp);
        }
    }

    public T SpawnObject()
    {
        //Check if we did not exceed our capacity, if we did, find available object
        if (_activeObjects < _capacity)
        {
            Debug.Log("Grabbed first unused");
            T freeObject = _objects[_activeObjects];
            ++_activeObjects;
            freeObject.Activate();
            freeObject.Available = false; //Flag as used
            return freeObject;
        }
        else
        {
            //Find avalaible object
            T availableObject = _objects.Find(x => x.Available.Equals(true));
            if (availableObject == null)
            {
                Debug.LogWarning("No available pool objects for object " + typeof(T));
                return null;
            }
            else
            {
                availableObject.Activate();
                availableObject.Available = false; //Flag as used
                Debug.Log("Reused pool object");
                return availableObject;
            }
        }
    }

    public void RemoveObject(T obj)
    {
        if (_objects.Find(x => x.Equals(obj)))
        {
            obj.Deactivate();
            obj.Available = true;
        }
    }
}
