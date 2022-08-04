import * as React from 'react';

import { Pressable, StyleSheet, Text, View } from 'react-native';
import { multiply } from 'react-native-kakao-sdk';

export default function App() {
  const [result, setResult] = React.useState<number | undefined>();

  React.useEffect(() => {
    multiply(3, 7).then(setResult);
  }, []);

  const onPress = () => {
    setResult((result ?? 0) + 1);
  };

  return (
    <View style={styles.container}>
      <Pressable onPress={onPress}>
        <Text>Result: {result}</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
