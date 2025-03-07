#if defined _knifemodels_included 
    #endinput
#endif 

#define _knifemodels_included

#if !defined _knifemodels_const_included
    #include <knifemodels_const>
#endif 

/** 
 * Called when the client changes his knife model.
 *
 * @param id                Client index.
 * @param knife             Knife index.
 * @param onconnect         True if this was called when the client joins the server, False otherwise.
 * @noreturn
 */
forward km_on_knife_updated( id, Knife, bool:onconnect );

/** 
 * Returns the total number of registered knives.
 *
 * @return                  Total number of registered knives.    
 */
native km_total_knives();

/** 
 * Returns the client's current knife.
 *
 * @param id                Client index.
 * @return                  Client's knife index.     
 */
native km_current_knife( id );

/** 
 * Checks whether or not the client has access to the specified knife.
 *
 * @param id                Client index. 
 * @param knife             Knife index.
 * @return                  True if the client has access to that knife, False otherwise.   
 */
native bool:km_has_knife_access( id, knife );

/** 
 * Check whether or not the knife index is valid.
 *
 * @param knife             Knife index.
 * @return                  True if the knife index is valid, False otherwise.  
 */
native bool:km_is_knife_valid( knife );




